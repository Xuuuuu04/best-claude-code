# Embedded Dev — RTOS Deep Dive

## FreeRTOS Fundamentals

### Task Management

```c
// Task creation with static allocation (preferred over dynamic)
StaticTask_t motor_task_tcb;
StackType_t motor_task_stack[512];

TaskHandle_t motor_task_h = xTaskCreateStatic(
    motor_task_fn,         // function
    "MotorTask",           // name (debug only)
    512,                   // stack words
    NULL,                  // parameters
    configMAX_PRIORITIES - 1, // highest priority
    motor_task_stack,
    &motor_task_tcb
);
```

**Priority assignment guidelines**:
- `configMAX_PRIORITIES - 1`: hard real-time (motor control, safety)
- `configMAX_PRIORITIES - 2`: time-sensitive (sensor read, comms)
- `configMAX_PRIORITIES / 2`: normal work (data processing, logging)
- `1`: background (IDLE+1): maintenance, low-priority housekeeping
- `0`: IDLE task (FreeRTOS internal)

### Synchronization Primitives

| Primitive | Use case | ISR-safe? |
|---|---|---|
| Binary semaphore | Signal from ISR to task | Yes (FromISR variant) |
| Counting semaphore | N resources / N events | Yes (FromISR variant) |
| Mutex | Protect shared resource | No (priority ceiling) |
| Queue | Pass data between tasks | Yes (FromISR variant) |
| Event flags | Wait for multiple conditions | Yes (FromISR variant) |
| Stream buffer | Streaming byte data (UART) | Yes (FromISR variant) |

**Golden rule**: ISR → task communication always uses FromISR variants.

```c
// Correct ISR to task signaling
void TIM2_IRQHandler(void) {
    HAL_TIM_IRQHandler(&htim2);
}

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
    if (htim == &htim2) {
        BaseType_t yield = pdFALSE;
        // Post sensor read event to queue
        sensor_event_t ev = {.type = SENSOR_READ, .timestamp = HAL_GetTick()};
        xQueueSendFromISR(sensor_queue, &ev, &yield);
        portYIELD_FROM_ISR(yield);
    }
}
```

### Stack Watermark Monitoring

```c
// During development / test: monitor high-water mark
void stack_monitor_task(void *pvParameters) {
    for (;;) {
        UBaseType_t watermark = uxTaskGetStackHighWaterMark(motor_task_h);
        if (watermark < 32) {  // < 32 words remaining = danger
            LOG_WARN("MotorTask stack low: %u words remaining", watermark);
        }
        vTaskDelay(pdMS_TO_TICKS(10000));
    }
}
```

Rule: stack watermark must be ≥ 20% of allocated stack in worst-case conditions.

### Tickless Idle (Power Saving)

```c
// In FreeRTOSConfig.h
#define configUSE_TICKLESS_IDLE  2  // 2 = custom implementation

// Implement vPortSuppressTicksAndSleep for your MCU
void vPortSuppressTicksAndSleep(TickType_t xExpectedIdleTime) {
    // 1. Calculate actual sleep duration
    // 2. Stop SysTick
    // 3. Enter MCU low-power mode
    // 4. On wake: correct FreeRTOS tick count
    // 5. Restart SysTick
}
```

---

## Zephyr RTOS

### Device Tree Node (STM32 SPI example)

```dts
&spi1 {
    status = "okay";
    pinctrl-0 = <&spi1_sck_pa5 &spi1_miso_pa6 &spi1_mosi_pa7>;
    pinctrl-names = "default";
    cs-gpios = <&gpioa 4 GPIO_ACTIVE_LOW>;

    lis3dh: lis3dh@0 {
        compatible = "st,lis3dh";
        reg = <0>;
        spi-max-frequency = <10000000>;
        irq-gpios = <&gpiob 0 GPIO_ACTIVE_HIGH>;
    };
};
```

### Kconfig Dependencies

```kconfig
config MY_DRIVER
    bool "Enable my driver"
    depends on SPI && GPIO
    select LIS3DH  # pulls in the sensor driver
    help
        Enable the custom sensor driver.
```

### Zephyr Work Queue (deferred ISR processing)

```c
static struct k_work sensor_work;

static void sensor_work_handler(struct k_work *work) {
    // Safe to call blocking APIs here (running in system workqueue)
    sensor_read_and_process();
}

static void gpio_callback(const struct device *dev,
                          struct gpio_callback *cb, gpio_port_pins_t pins) {
    k_work_submit(&sensor_work);  // defer, don't process in ISR
}
```

---

## Priority Inversion — Analysis and Fix

### Detection

Priority inversion occurs when:
1. Task H (high priority) waits for resource held by Task L (low priority)
2. Task M (medium priority) preempts Task L
3. Task H waits indefinitely while Task M runs (unbounded inversion)

Symptoms:
- High-priority task misses deadlines intermittently
- Timing analysis shows medium-priority task running when high-priority should
- Difficult to reproduce — occurs only under specific load combinations

### Fix: Priority Ceiling Protocol

```c
// Create mutex with priority ceiling = highest task that uses it
SemaphoreHandle_t spi_mutex = xSemaphoreCreateMutex();
// FreeRTOS priority inheritance: enabled when configUSE_MUTEXES=1
// Inheritance: when Task L holds mutex, its priority is temporarily raised
// to match the highest task waiting for the mutex

// Usage pattern:
if (xSemaphoreTake(spi_mutex, pdMS_TO_TICKS(10)) == pdTRUE) {
    spi_transfer(data, len);
    xSemaphoreGive(spi_mutex);
} else {
    LOG_ERR("SPI mutex timeout — possible deadlock or resource starvation");
    // Do NOT proceed without the mutex
}
```

### Deadlock Prevention

Never allow a task to hold two mutexes simultaneously without a consistent
lock ordering. If `mutex_A` and `mutex_B` must both be held:
- Always acquire in order: A then B
- Never: some tasks A→B, others B→A

---

## Real-Time Guarantee Analysis

### WCET Estimation for Critical ISR

For ISR body WCET estimation:
1. Count instruction cycles for worst-case path (branch all taken)
2. Add data cache miss penalty (if applicable)
3. Add interrupt latency (hardware response time, typically 12-68 cycles on Cortex-M)
4. Total must be ≤ constraint (e.g., 500 cycles at 96MHz = 5.2µs)

Tools: ARM Cycle Counter (`DWT->CYCCNT`), logic analyzer on GPIO toggle in ISR.

```c
// ISR timing measurement (debug only, remove for production)
static uint32_t isr_max_cycles = 0;
void EXTI0_IRQHandler(void) {
    uint32_t start = DWT->CYCCNT;
    // ISR body
    uint32_t cycles = DWT->CYCCNT - start;
    if (cycles > isr_max_cycles) isr_max_cycles = cycles;
}
```
