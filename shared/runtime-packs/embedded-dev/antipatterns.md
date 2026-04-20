# Embedded Dev — Anti-Patterns Reference

See also: `core.md §Anti-Patterns` for brief descriptions.
This file provides extended analysis, detection examples, and fix patterns.

---

## Anti-Pattern 1: malloc-in-ISR (CRITICAL)

**Description**: Using dynamic memory allocation from within an ISR or any
callback invoked at interrupt priority.

**Detection patterns** (grep targets):
```bash
grep -rn "pvPortMalloc\|vPortFree\|malloc\|calloc\|realloc\|new " \
  --include="*.c" --include="*.cpp" src/
# Then filter for functions named *_IRQHandler, *_Callback, *_ISR
```

**Why it fails**:
- FreeRTOS heap functions are protected by a mutex/critical section
- The mutex cannot be acquired from ISR context (would deadlock)
- Even if the heap is non-mutex (heap_1.c), size checking is not ISR-safe
- Result: HardFault, watchdog reset, or memory corruption

**Fix patterns**:
```c
// Instead of: dynamic allocation in ISR
// void DMA_IRQHandler() { msg = pvPortMalloc(sizeof(msg_t)); ... }

// Fix 1: Static pool (preferred)
static msg_t msg_pool[MSG_POOL_SIZE];
static uint8_t msg_pool_used[MSG_POOL_SIZE] = {0};
msg_t *msg_pool_alloc(void) { /* find free slot */ }

// Fix 2: Fixed-size queue with pre-allocated messages
#define QUEUE_DEPTH 8
static msg_t queue_storage[QUEUE_DEPTH];
static uint8_t queue_head = 0, queue_tail = 0;

// Fix 3: Stream buffer (FreeRTOS 10.x, ISR-safe)
xStreamBufferSendFromISR(stream_buf, data, len, &yield);
```

---

## Anti-Pattern 2: ISR-Too-Long (HIGH)

**Description**: ISR body performing significant computation, blocking operations,
or deferred work that should be in a task.

**Detection**: ISR functions exceeding 20 lines, or containing:
- Loops with variable iteration count
- String formatting / printf
- File I/O or UART blocking transmit
- SHA/CRC computation over large buffers
- Complex state machine transitions

**Why it fails**:
- Blocks interrupts of equal or lower priority
- Causes real-time deadline misses in time-critical systems
- Unpredictable execution time makes WCET analysis meaningless
- High interrupt load causes RTOS tick starvation

**Fix template**:
```c
// BAD: long ISR
void USART1_IRQHandler(void) {
    char *data = receive_byte();
    parse_nmea_frame(data);      // can take 1ms+
    update_gps_position(data);
    log_to_flash(data);          // definitely wrong
}

// GOOD: minimal ISR + task
void USART1_IRQHandler(void) {
    uint8_t byte = (uint8_t)USART1->DR;
    BaseType_t yield = pdFALSE;
    xQueueSendFromISR(uart_rx_queue, &byte, &yield);
    portYIELD_FROM_ISR(yield);
}

void gps_task(void *pv) {
    uint8_t byte;
    for (;;) {
        xQueueReceive(uart_rx_queue, &byte, portMAX_DELAY);
        // All the heavy processing here, at task priority
        nmea_parser_feed(byte);
    }
}
```

---

## Anti-Pattern 3: Priority Inversion Unguarded (HIGH)

See `rtos.md §Priority Inversion` for full analysis.

**Quick detection**: multiple tasks sharing a mutex where task priorities differ
by more than one level, without priority inheritance configured.

**Quick fix**: ensure `configUSE_MUTEXES=1` in FreeRTOSConfig.h (enables priority
inheritance). Consider priority ceiling for deterministic behavior.

---

## Anti-Pattern 4: OTA Without Rollback (CRITICAL)

**Detection**: OTA implementation with any of:
- Single-bank flash (no staging partition)
- No watchdog reset supervision of first boot
- No `ota_confirm()` / `boot_set_confirmed()` pattern
- Rollback path never tested

See `ota.md` for complete fix patterns.

---

## Anti-Pattern 5: Global Variables as IPC (HIGH)

**Description**: Using global variables for data shared between tasks or between
ISR and task, without protection.

**Detection**:
```bash
# Find global variables modified in both ISR handlers and tasks
grep -n "^volatile\|^static volatile\|^extern volatile" src/*.c
# Then check if same variable appears in both IRQHandler and task functions
```

**Why it fails**:
- ARM Cortex-M does not guarantee atomic access to multi-byte variables
- A context switch mid-write produces torn reads
- Compiler optimization can cache values in registers, bypassing the actual variable

**Fix patterns**:
```c
// For flag-type IPC: use FreeRTOS event groups or semaphores
// For data-type IPC: use queues or stream buffers
// For configuration read by task, written rarely: use taskENTER_CRITICAL / taskEXIT_CRITICAL

// If you MUST use a global (document why):
volatile uint32_t g_adc_result;  // volatile prevents register caching
// Then protect multi-byte access:
taskENTER_CRITICAL();
uint32_t local_copy = g_adc_result;
taskEXIT_CRITICAL();
```

---

## Anti-Pattern 6: Blocking in Tight Loop (MEDIUM)

**Description**: Polling a hardware register or flag in a busy loop without
yielding to RTOS scheduler.

```c
// BAD: 100% CPU utilization while waiting
while (!(USART1->SR & USART_SR_RXNE)) { }  // spin-wait

// GOOD: yield to scheduler
xQueueReceive(uart_rx_queue, &byte, pdMS_TO_TICKS(100));  // yield until data
// or use event-driven pattern with ISR posting to queue
```

---

## Anti-Pattern 7: Unused Return Values from Critical Functions (HIGH)

**Description**: Ignoring return values from HAL functions, especially in initialization.

```c
// BAD
HAL_I2C_Init(&hi2c1);  // ignores HAL_OK / HAL_ERROR
HAL_SPI_Transmit(&hspi1, buf, len, 100);

// GOOD
if (HAL_I2C_Init(&hi2c1) != HAL_OK) {
    Error_Handler();  // never silently proceed with uninitialized peripheral
}
```

---

## Anti-Pattern 8: Stack Overflow Uncaught (CRITICAL for safety)

**Description**: Task stacks too small for actual call depth + local variables.

**Detection tool**:
```c
// Enable stack overflow checking
#define configCHECK_FOR_STACK_OVERFLOW 2  // in FreeRTOSConfig.h

void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName) {
    // Log the task name, then reset or halt
    LOG_ERR("STACK OVERFLOW: %s", pcTaskName);
    __BKPT(0);  // halt in debug
    NVIC_SystemReset();  // reset in production
}
```

**Prevention**: allocate stacks with 30% margin over measured watermark.

---

## Anti-Pattern 9: Watchdog Not Fed Correctly (HIGH)

**Description**: IWDG/WWDG fed from a single task, which means a stuck ISR or
other task won't be detected.

**Fix**: Use an RTOS watchdog pattern where each critical task sets a bit in
an event group, and a watchdog task only feeds the hardware watchdog when all
bits are set:

```c
#define WDG_BITS_MOTOR  (1 << 0)
#define WDG_BITS_SENSOR (1 << 1)
#define WDG_BITS_COMMS  (1 << 2)
#define WDG_BITS_ALL    (WDG_BITS_MOTOR | WDG_BITS_SENSOR | WDG_BITS_COMMS)

EventGroupHandle_t wdg_event_group;

void watchdog_task(void *pv) {
    for (;;) {
        EventBits_t bits = xEventGroupWaitBits(
            wdg_event_group, WDG_BITS_ALL, pdTRUE, pdTRUE,
            pdMS_TO_TICKS(1000)  // all tasks must check in within 1s
        );
        if ((bits & WDG_BITS_ALL) == WDG_BITS_ALL) {
            HAL_IWDG_Refresh(&hiwdg);  // all healthy
        }
        // If timeout: watchdog fires, system resets
    }
}

// In each critical task:
void motor_task(void *pv) {
    for (;;) {
        // ... motor work ...
        xEventGroupSetBits(wdg_event_group, WDG_BITS_MOTOR);
        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(100));
    }
}
```
