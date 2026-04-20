# Embedded Dev — Anti-Patterns Reference

## Named Anti-Patterns

---

### Anti-Pattern 1: malloc-in-ISR (CRITICAL)

**Definition**: Using dynamic memory allocation from within an ISR or any callback invoked at interrupt priority.

**Manifestations**:
```c
// BAD — FORBIDDEN
void DMA_IRQHandler(void) {
    msg_t *msg = pvPortMalloc(sizeof(msg_t));  // DEADLOCK
    msg->data = ADC1->DR;
    xQueueSendFromISR(queue, msg, NULL);
}

// BAD — FORBIDDEN
void TIM2_IRQHandler(void) {
    uint8_t *buf = malloc(256);  // CORRUPTION
    sprintf(buf, "tick=%lu", HAL_GetTick());
}
```

**Why it's dangerous**: FreeRTOS heap functions are protected by a mutex/critical section. The mutex cannot be acquired from ISR context (would deadlock). Even if the heap is non-mutex (heap_1.c), size checking is not ISR-safe. Result: HardFault, watchdog reset, or memory corruption.

**Correction**: Every ISR must use pre-allocated structures.

```c
// GOOD — static pool
static msg_t msg_pool[MSG_POOL_SIZE];
static volatile uint8_t msg_pool_used[MSG_POOL_SIZE] = {0};

msg_t *msg_pool_alloc(void) {
    for (int i = 0; i < MSG_POOL_SIZE; i++) {
        if (!msg_pool_used[i]) {
            msg_pool_used[i] = 1;
            return &msg_pool[i];
        }
    }
    return NULL;  // Pool exhausted
}

void DMA_IRQHandler(void) {
    msg_t *msg = msg_pool_alloc();
    if (msg) {
        msg->data = ADC1->DR;
        BaseType_t yield = pdFALSE;
        xQueueSendFromISR(queue, &msg, &yield);
        portYIELD_FROM_ISR(yield);
    }
}
```

```c
// GOOD — fixed-size queue with pre-allocated messages
#define QUEUE_DEPTH 8
static msg_t queue_storage[QUEUE_DEPTH];
static StaticQueue_t queue_buffer;
static QueueHandle_t queue;

void init_queue(void) {
    queue = xQueueCreateStatic(QUEUE_DEPTH, sizeof(msg_t),
                               (uint8_t *)queue_storage, &queue_buffer);
}

void DMA_IRQHandler(void) {
    msg_t msg = {.data = ADC1->DR, .timestamp = HAL_GetTick()};
    BaseType_t yield = pdFALSE;
    xQueueSendFromISR(queue, &msg, &yield);  // Copy into queue storage
    portYIELD_FROM_ISR(yield);
}
```

---

### Anti-Pattern 2: ISR-Too-Long (HIGH)

**Definition**: ISR body performing significant computation, blocking operations, or deferred work that should be in a task.

**Manifestations**:
```c
// BAD — FORBIDDEN: long ISR with parsing and flash write
void USART1_IRQHandler(void) {
    char *data = receive_byte();
    parse_nmea_frame(data);      // Can take 1ms+
    update_gps_position(data);
    log_to_flash(data);          // Flash write in ISR — WRONG
}

// BAD — FORBIDDEN: printf in ISR
void TIM2_IRQHandler(void) {
    printf("Timer tick: %lu\n", HAL_GetTick());  // UART blocking
}
```

**Why it's dangerous**: Blocks interrupts of equal or lower priority. Causes real-time deadline misses in time-critical systems. Unpredictable execution time makes WCET analysis meaningless. High interrupt load causes RTOS tick starvation.

**Correction**: Minimal ISR + deferred task processing.

```c
// GOOD — minimal ISR
void USART1_IRQHandler(void) {
    uint8_t byte = (uint8_t)USART1->DR;
    BaseType_t yield = pdFALSE;
    xQueueSendFromISR(uart_rx_queue, &byte, &yield);
    portYIELD_FROM_ISR(yield);
}

// GOOD — heavy processing in task
void gps_task(void *pv) {
    uint8_t byte;
    static char nmea_buf[128];
    static uint8_t idx = 0;
    
    for (;;) {
        xQueueReceive(uart_rx_queue, &byte, portMAX_DELAY);
        
        if (byte == '$') idx = 0;
        nmea_buf[idx++] = byte;
        
        if (byte == '\n' && idx > 0) {
            nmea_buf[idx] = '\0';
            parse_nmea_frame(nmea_buf);  // Safe: runs at task priority
            update_gps_position();
            idx = 0;
        }
    }
}
```

---

### Anti-Pattern 3: Priority Inversion Unguarded (HIGH)

**Definition**: High-priority task waits indefinitely on a mutex held by a low-priority task, while medium-priority tasks preempt the low-priority task.

**Manifestations**:
```c
// BAD — FORBIDDEN: mutex without priority inheritance
SemaphoreHandle_t spi_mutex = xSemaphoreCreateMutex();  // OK, but...

// Task L (low priority, priority 1) takes mutex
void sensor_task(void *pv) {
    xSemaphoreTake(spi_mutex, portMAX_DELAY);
    // ... long SPI transfer ...
    // Task M (priority 2) preempts here!
    // Task H (priority 3) waits on mutex indefinitely
    xSemaphoreGive(spi_mutex);
}
```

**Why it's dangerous**: High-priority task misses deadlines intermittently. Difficult to reproduce — occurs only under specific load combinations. Can cause system-wide timing failures.

**Correction**: Priority inheritance mutex with consistent lock ordering.

```c
// GOOD — priority inheritance enabled (configUSE_MUTEXES=1)
SemaphoreHandle_t spi_mutex = xSemaphoreCreateMutex();

// When Task L holds mutex and Task H tries to take it:
// Task L's priority temporarily raised to Task H's level
// Task L runs to completion, gives mutex back
// Task H takes mutex and continues

// GOOD — always use timeout, never block forever
if (xSemaphoreTake(spi_mutex, pdMS_TO_TICKS(10)) == pdTRUE) {
    spi_transfer(data, len);
    xSemaphoreGive(spi_mutex);
} else {
    LOG_ERR("SPI mutex timeout — possible deadlock");
    // Handle error, do NOT proceed without mutex
}
```

---

### Anti-Pattern 4: OTA Without Rollback (CRITICAL)

**Definition**: OTA implementation lacking dual-bank flash, watchdog supervision, or automatic rollback on failed first boot.

**Manifestations**:
```c
// BAD — FORBIDDEN: single-bank OTA
void ota_update(uint8_t *new_firmware, size_t len) {
    flash_erase(0x08000000, len);        // Erase current firmware!
    flash_write(0x08000000, new_firmware, len);  // Write new
    NVIC_SystemReset();                   // Pray it works
    // If new firmware is corrupt: BRICKED DEVICE
}

// BAD — FORBIDDEN: no watchdog supervision
void app_main(void) {
    // No check for pending OTA state
    // No validation timer
    // If app crashes: no rollback
}
```

**Why it's dangerous**: A bricked device in the field requires physical reflashing or return to service. Unrecoverable for deployed fleets. A single bad OTA can disable thousands of devices.

**Correction**: Dual-bank with MCUboot + watchdog confirmation pattern.

```c
// GOOD — dual-bank with MCUboot
// Flash layout:
// 0x08000000: Bootloader (64KB)
// 0x08010000: Bank A (active)
// 0x08080000: Bank B (staging)

// Application first boot after OTA:
void app_main(void) {
    bool ota_pending = (boot_swap_type() == BOOT_SWAP_TYPE_REVERT);
    if (ota_pending) {
        start_watchdog(90);  // 90 second timeout
        // Run self-tests...
        if (self_tests_pass()) {
            boot_set_confirmed();  // Mark permanent
            stop_watchdog();
        }
        // If not confirmed: watchdog fires -> bootloader rolls back
    }
}
```

---

### Anti-Pattern 5: Global Variables as IPC (HIGH)

**Definition**: Using global variables for data shared between tasks or between ISR and task, without protection.

**Manifestations**:
```c
// BAD — FORBIDDEN: unprotected global shared between ISR and task
volatile uint32_t g_sensor_value;  // Written by ISR, read by task

void ADC_IRQHandler(void) {
    g_sensor_value = ADC1->DR;  // 32-bit write on Cortex-M is NOT atomic
}

void sensor_task(void *pv) {
    uint32_t val = g_sensor_value;  // May read torn value
}
```

**Why it's dangerous**: ARM Cortex-M does not guarantee atomic access to multi-byte variables. A context switch mid-write produces torn reads. Compiler optimization can cache values in registers, bypassing the actual variable.

**Correction**: Use RTOS primitives for all IPC.

```c
// GOOD — queue for data transfer
QueueHandle_t sensor_queue;

void ADC_IRQHandler(void) {
    uint32_t value = ADC1->DR;
    BaseType_t yield = pdFALSE;
    xQueueSendFromISR(sensor_queue, &value, &yield);
    portYIELD_FROM_ISR(yield);
}

void sensor_task(void *pv) {
    uint32_t value;
    xQueueReceive(sensor_queue, &value, portMAX_DELAY);
    // Process complete, valid value
}
```

```c
// GOOD — event flags for signaling
EventGroupHandle_t event_group;

void TIM2_IRQHandler(void) {
    BaseType_t yield = pdFALSE;
    xEventGroupSetBitsFromISR(event_group, EVENT_SAMPLE_READY, &yield);
    portYIELD_FROM_ISR(yield);
}

void processing_task(void *pv) {
    EventBits_t bits = xEventGroupWaitBits(event_group, EVENT_SAMPLE_READY,
                                            pdTRUE, pdFALSE, portMAX_DELAY);
    // Process sample
}
```

---

### Anti-Pattern 6: Blocking in Tight Loop (MEDIUM)

**Definition**: Polling a hardware register or flag in a busy loop without yielding to RTOS scheduler.

**Manifestations**:
```c
// BAD — FORBIDDEN: spin-wait wastes 100% CPU
while (!(USART1->SR & USART_SR_RXNE)) { }  // Spin-wait
USART1->DR = data;

// BAD — FORBIDDEN: HAL_Delay in task without yield
void task(void *pv) {
    for (;;) {
        read_sensor();
        HAL_Delay(100);  // vTaskDelay is better, but still polling
    }
}
```

**Why it's dangerous**: Wastes CPU cycles that other tasks need. Prevents tickless idle from entering low-power modes. Inefficient power usage.

**Correction**: Event-driven architecture with ISR notification.

```c
// GOOD — yield until data available
void uart_task(void *pv) {
    uint8_t byte;
    for (;;) {
        xQueueReceive(uart_rx_queue, &byte, portMAX_DELAY);  // Yield until data
        process_byte(byte);
    }
}

// GOOD — periodic task with precise timing
void sensor_task(void *pv) {
    TickType_t last_wake = xTaskGetTickCount();
    for (;;) {
        read_sensor();
        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(100));  // Precise 100ms period
    }
}
```

---

### Anti-Pattern 7: Unused Return Values from Critical Functions (HIGH)

**Definition**: Ignoring return values from HAL functions, especially in initialization.

**Manifestations**:
```c
// BAD — FORBIDDEN: ignoring init result
HAL_I2C_Init(&hi2c1);  // HAL_OK? HAL_ERROR? Who knows?
HAL_SPI_Transmit(&hspi1, buf, len, 100);  // Timeout ignored

// BAD — FORBIDDEN: ignoring error in loop
while (HAL_I2C_GetState(&hi2c1) != HAL_I2C_STATE_READY) {
    // Infinite loop if I2C stuck
}
```

**Why it's dangerous**: Silent initialization failures cause mysterious runtime behavior. A peripheral that "should work" produces garbage data. Timeout ignored means infinite hangs.

**Correction**: Check every return value, handle errors explicitly.

```c
// GOOD — check and handle
if (HAL_I2C_Init(&hi2c1) != HAL_OK) {
    Error_Handler();  // Log error, enter safe state
}

HAL_StatusTypeDef status = HAL_SPI_Transmit(&hspi1, buf, len, 100);
if (status == HAL_TIMEOUT) {
    LOG_ERR("SPI timeout — possible bus stuck");
    spi_bus_recovery(&hspi1);
} else if (status != HAL_OK) {
    LOG_ERR("SPI error: %d", status);
    return ERR_SPI_FAIL;
}
```

---

### Anti-Pattern 8: Stack Overflow Uncaught (CRITICAL)

**Definition**: Task stacks too small for actual call depth + local variables.

**Manifestations**:
```c
// BAD — FORBIDDEN: tiny stack for complex task
xTaskCreate(complex_task, "Complex", 128, NULL, 1, NULL);  // 128 words = 512 bytes
// Task calls printf (large stack) + recursive parser = overflow
```

**Why it's dangerous**: Stack overflow corrupts adjacent task stacks or kernel data. HardFault at random locations. Extremely difficult to debug.

**Correction**: Enable stack checking, monitor watermarks, allocate with margin.

```c
// GOOD — enable overflow checking
#define configCHECK_FOR_STACK_OVERFLOW  2

void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName) {
    LOG_ERR("STACK OVERFLOW: %s", pcTaskName);
    __BKPT(0);
    NVIC_SystemReset();
}

// GOOD — monitor watermark
void stack_monitor_task(void *pv) {
    for (;;) {
        UBaseType_t wm = uxTaskGetStackHighWaterMark(task_handle);
        if (wm < 64) {  // Less than 64 words free
            LOG_WARN("Stack low: %s — %u words", pcTaskName, wm);
        }
        vTaskDelay(pdMS_TO_TICKS(30000));
    }
}
```

---

### Anti-Pattern 9: Watchdog Not Fed Correctly (HIGH)

**Definition**: IWDG/WWDG fed from a single task, which means a stuck ISR or other task won't be detected.

**Manifestations**:
```c
// BAD — FORBIDDEN: single task feeds watchdog
void main_task(void *pv) {
    for (;;) {
        do_work();
        HAL_IWDG_Refresh(&hiwdg);  // What if motor task is stuck?
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}
```

**Why it's dangerous**: A stuck motor control task or frozen ISR won't be detected. The watchdog only monitors the feeding task, not the system as a whole.

**Correction**: Multi-task watchdog pattern.

```c
// GOOD — RTOS-aware watchdog (see rtos-deep-dive.md)
// Each critical task sets a bit in an event group
// Watchdog task only feeds when ALL bits are set

#define WDG_BITS_MOTOR  (1 << 0)
#define WDG_BITS_SENSOR (1 << 1)
#define WDG_BITS_COMMS  (1 << 2)

EventGroupHandle_t wdg_event_group;

void watchdog_task(void *pv) {
    for (;;) {
        EventBits_t bits = xEventGroupWaitBits(
            wdg_event_group, WDG_BITS_ALL,
            pdTRUE, pdTRUE, pdMS_TO_TICKS(1000)
        );
        if ((bits & WDG_BITS_ALL) == WDG_BITS_ALL) {
            HAL_IWDG_Refresh(&hiwdg);
        }
        // If timeout: watchdog fires, system resets
    }
}
```

---

### Anti-Pattern 10: Power Gating Neglect (HIGH)

**Definition**: Leaving peripheral clocks enabled during sleep modes, causing excessive sleep current.

**Manifestations**:
```c
// BAD — FORBIDDEN: entering sleep without clock cleanup
void enter_sleep(void) {
    // SPI1 clock still running!
    // UART still enabled!
    // ADC still consuming power!
    HAL_PWR_EnterSTOPMode(PWR_LOWPOWERREGULATOR_ON, PWR_STOPENTRY_WFI);
}
```

**Why it's dangerous**: Unclocked peripherals can consume 10-100x more current than the CPU in sleep mode. A device that should last years on battery drains in weeks.

**Correction**: Systematic power gating checklist.

```c
// GOOD — complete power gating
void enter_deep_sleep(uint32_t seconds) {
    // 1. Complete all transactions
    while (HAL_SPI_GetState(&hspi1) != HAL_SPI_STATE_READY) {
        osDelay(1);
    }
    
    // 2. Put peripherals in low-power mode
    HAL_SPI_DeInit(&hspi1);
    HAL_UART_DeInit(&huart1);
    HAL_ADC_DeInit(&hadc1);
    
    // 3. Disable peripheral clocks
    __HAL_RCC_SPI1_CLK_DISABLE();
    __HAL_RCC_USART1_CLK_DISABLE();
    __HAL_RCC_ADC_CLK_DISABLE();
    
    // 4. Configure GPIO for minimum leakage
    GPIO_InitTypeDef GPIO_InitStruct = {0};
    GPIO_InitStruct.Pin = GPIO_PIN_All;
    GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);  // All pins analog
    
    // 5. Enable wakeup source
    HAL_RTCEx_SetWakeUpTimer_IT(&hrtc, seconds, RTC_WAKEUPCLOCK_CK_SPRE_16BITS);
    
    // 6. Enter low-power mode
    HAL_PWR_EnterSTOPMode(PWR_LOWPOWERREGULATOR_ON, PWR_STOPENTRY_WFI);
    
    // 7. On wakeup: restore clocks and peripherals
    SystemClock_Config();
    __HAL_RCC_SPI1_CLK_ENABLE();
    HAL_SPI_Init(&hspi1);
    // ... restore other peripherals
}
```
