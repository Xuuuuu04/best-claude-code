# Embedded Dev — RTOS Deep Dive

## FreeRTOS Advanced Patterns

### Task Notifications (Lightweight Synchronization)

Task notifications are the fastest IPC mechanism in FreeRTOS — 45% faster than binary semaphores, uses zero extra RAM.

```c
// Task waiting for notification
void sensor_task(void *pv) {
    for (;;) {
        // Block until ISR notifies — equivalent to semaphore take
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
        // Process sensor data
        process_samples();
    }
}

// ISR notifying task
void adc_isr(void) {
    BaseType_t yield = pdFALSE;
    vTaskNotifyGiveFromISR(sensor_task_handle, &yield);
    portYIELD_FROM_ISR(yield);
}
```

**Notification value as event mask**:
```c
// Multiple event types via notification bits
#define EVENT_ADC_DONE  (1 << 0)
#define EVENT_UART_RX   (1 << 1)
#define EVENT_TIMEOUT   (1 << 2)

void event_task(void *pv) {
    for (;;) {
        uint32_t events = ulTaskNotifyWait(0, ULONG_MAX, &events, portMAX_DELAY);
        if (events & EVENT_ADC_DONE) process_adc();
        if (events & EVENT_UART_RX) process_uart();
    }
}
```

### Heap Selection Guide

| Heap | Use Case | Pros | Cons |
|------|----------|------|------|
| heap_1 | Static allocation only, no free | Deterministic, simplest | No deallocation |
| heap_2 | Old, deprecated | — | Fragmentation, don't use |
| heap_3 | Wrapper around malloc/free | Uses libc malloc | Not deterministic, needs thread safety |
| heap_4 | Coalescing free blocks | Defragments, most flexible | Slight overhead |
| heap_5 | Multiple non-contiguous regions | External RAM support | Complex setup |

**Recommended**: heap_4 for most applications; heap_1 for safety-critical (no dynamic free).

### Tickless Idle Implementation

```c
// In FreeRTOSConfig.h
#define configUSE_TICKLESS_IDLE  2  // 2 = custom implementation
#define configEXPECTED_IDLE_TIME_BEFORE_SLEEP  2  // ticks

// Custom sleep implementation
void vPortSuppressTicksAndSleep(TickType_t xExpectedIdleTime) {
    uint32_t ulCompleteTickPeriods;
    
    // Stop SysTick
    SysTick->CTRL &= ~SysTick_CTRL_ENABLE_Msk;
    
    // Calculate actual sleep duration in microseconds
    uint32_t sleep_us = xExpectedIdleTime * 1000;  // assuming 1ms tick
    
    // Configure RTC wakeup
    HAL_RTCEx_SetWakeUpTimer_IT(&hrtc, sleep_us / 30, RTC_WAKEUPCLOCK_RTCCLK_DIV);
    
    // Enter low-power mode
    HAL_PWR_EnterSTOPMode(PWR_LOWPOWERREGULATOR_ON, PWR_STOPENTRY_WFI);
    
    // On wake: calculate how many ticks passed
    uint32_t elapsed_us = /* read RTC elapsed */;
    ulCompleteTickPeriods = elapsed_us / 1000;
    
    // Correct FreeRTOS tick count
    vTaskStepTick(ulCompleteTickPeriods);
    
    // Restart SysTick
    SysTick->CTRL |= SysTick_CTRL_ENABLE_Msk;
}
```

---

## Zephyr RTOS Deep Dive

### Device Tree Bindings

Device tree describes hardware configuration independently of source code.

```dts
// board.overlay — add sensor to SPI bus
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

### Kconfig Dependency Management

```kconfig
# Kconfig for custom driver
config MY_SENSOR_DRIVER
    bool "Enable MY sensor driver"
    depends on SPI && GPIO
    select SENSOR  # Pulls in sensor subsystem
    help
        Enable support for the MY accelerometer sensor.
        Requires SPI bus and GPIO for interrupt pin.

config MY_SENSOR_SAMPLING_RATE
    int "Default sampling rate in Hz"
    default 100
    range 1 1000
    depends on MY_SENSOR_DRIVER
```

### Zephyr Work Queues (Deferred ISR Processing)

```c
static struct k_work sensor_work;

static void sensor_work_handler(struct k_work *work) {
    // Runs in system workqueue context — can use blocking APIs
    struct sensor_value accel[3];
    sensor_sample_fetch(dev);
    sensor_channel_get(dev, SENSOR_CHAN_ACCEL_XYZ, accel);
    // Process and queue for transmission
}

static void gpio_callback(const struct device *dev,
                          struct gpio_callback *cb, gpio_port_pins_t pins) {
    // ISR context — just defer to work queue
    k_work_submit(&sensor_work);
}
```

### Zephyr Memory Management

```c
// Memory slabs — fixed-size allocation, deterministic
K_MEM_SLAB_DEFINE(my_slab, 64, 16, 4);  // 16 blocks of 64 bytes, 4-byte aligned

void *block;
if (k_mem_slab_alloc(&my_slab, &block, K_NO_WAIT) == 0) {
    // Use block
    k_mem_slab_free(&my_slab, block);
}
```

---

## Priority Inversion — Complete Analysis

### Detection Criteria

Priority inversion occurs when ALL of the following are true:
1. Task H (high priority) waits for resource held by Task L (low priority)
2. Task M (medium priority) preempts Task L
3. Task H waits indefinitely while Task M runs

### Priority Inheritance Protocol (FreeRTOS)

```c
// FreeRTOS mutex with priority inheritance (enabled by configUSE_MUTEXES=1)
SemaphoreHandle_t spi_mutex = xSemaphoreCreateMutex();

// When Task L holds the mutex and Task H tries to take it:
// 1. Task L's priority is temporarily raised to Task H's priority
// 2. Task L runs until it gives the mutex back
// 3. Task L's priority returns to its original level
// 4. Task H takes the mutex and continues

// Usage with timeout (never block forever):
if (xSemaphoreTake(spi_mutex, pdMS_TO_TICKS(10)) == pdTRUE) {
    spi_transfer(data, len);
    xSemaphoreGive(spi_mutex);
} else {
    LOG_ERR("SPI mutex timeout — possible deadlock");
    // Handle error, do NOT proceed without mutex
}
```

### Priority Ceiling Protocol (Deterministic)

```c
// Priority ceiling: mutex ceiling = highest priority of any task that uses it
// When Task L takes the mutex, its priority is immediately raised to ceiling
// No intermediate priority boost needed — deterministic behavior

// Implementation: assign ceiling at mutex creation
// In FreeRTOS: use mutex with configUSE_MUTEXES and analyze ceiling manually
// In Zephyr: k_mutex with priority inheritance built-in
```

### Deadlock Prevention — Consistent Lock Ordering

```c
// If two mutexes must be held simultaneously, ALWAYS acquire in the same order
// Global order: mutex_A before mutex_B

// Task 1 (correct):
xSemaphoreTake(mutex_A, portMAX_DELAY);
xSemaphoreTake(mutex_B, portMAX_DELAY);
// ... work ...
xSemaphoreGive(mutex_B);
xSemaphoreGive(mutex_A);

// Task 2 (correct — same order):
xSemaphoreTake(mutex_A, portMAX_DELAY);
xSemaphoreTake(mutex_B, portMAX_DELAY);
// ... work ...
xSemaphoreGive(mutex_B);
xSemaphoreGive(mutex_A);

// NEVER: Task 2 takes B then A — this creates a deadlock cycle
```

---

## Stack Management

### Stack Overflow Detection

```c
// Enable in FreeRTOSConfig.h
#define configCHECK_FOR_STACK_OVERFLOW  2  // Method 2: check stack canary

// Hook function
void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName) {
    LOG_ERR("STACK OVERFLOW in task: %s", pcTaskName);
    __BKPT(0);  // Halt in debug
    NVIC_SystemReset();  // Reset in production
}
```

### Stack Watermark Monitoring

```c
void stack_monitor_task(void *pv) {
    for (;;) {
        TaskHandle_t tasks[] = {motor_task_h, sensor_task_h, comms_task_h};
        const char *names[] = {"Motor", "Sensor", "Comms"};
        
        for (int i = 0; i < 3; i++) {
            UBaseType_t watermark = uxTaskGetStackHighWaterMark(tasks[i]);
            UBaseType_t total = 512;  // known stack size
            float used_pct = (1.0f - (float)watermark / total) * 100;
            
            if (watermark < 32) {  // < 32 words = danger
                LOG_ERR("Stack LOW: %s — %u words free (%.1f%% used)",
                        names[i], watermark, used_pct);
            } else if (watermark < 64) {
                LOG_WARN("Stack warning: %s — %u words free", names[i], watermark);
            }
        }
        vTaskDelay(pdMS_TO_TICKS(30000));  // Check every 30s
    }
}
```

### Stack Size Guidelines

| Task Type | Min Stack (words) | Recommended (words) | Notes |
|-----------|-------------------|---------------------|-------|
| Simple LED blink | 64 | 128 | No function calls |
| Sensor polling | 128 | 256 | HAL function calls |
| Communication (UART/SPI) | 256 | 512 | Protocol parsing, string ops |
| Complex algorithm | 512 | 1024 | Floating point, recursion |
| BLE stack (Nordic) | 1024 | 1536 | SoftDevice requires large stack |

---

## Watchdog Design Patterns

### RTOS-Aware Watchdog (Multi-Task)

```c
#define WDG_BITS_MOTOR  (1 << 0)
#define WDG_BITS_SENSOR (1 << 1)
#define WDG_BITS_COMMS  (1 << 2)
#define WDG_BITS_ALL    (WDG_BITS_MOTOR | WDG_BITS_SENSOR | WDG_BITS_COMMS)

EventGroupHandle_t wdg_event_group;

void watchdog_task(void *pv) {
    for (;;) {
        // Wait for ALL tasks to check in (1 second timeout)
        EventBits_t bits = xEventGroupWaitBits(
            wdg_event_group, WDG_BITS_ALL,
            pdTRUE,   // Clear bits on exit
            pdTRUE,   // Wait for ALL bits
            pdMS_TO_TICKS(1000)
        );
        
        if ((bits & WDG_BITS_ALL) == WDG_BITS_ALL) {
            HAL_IWDG_Refresh(&hiwdg);  // All healthy
        } else {
            // Identify which task missed check-in
            LOG_ERR("Watchdog timeout — missing: %s%s%s",
                    (bits & WDG_BITS_MOTOR) ? "" : "motor ",
                    (bits & WDG_BITS_SENSOR) ? "" : "sensor ",
                    (bits & WDG_BITS_COMMS) ? "" : "comms");
            // Do NOT refresh — let watchdog reset system
        }
    }
}

// Each critical task:
void motor_task(void *pv) {
    for (;;) {
        // ... motor control work ...
        xEventGroupSetBits(wdg_event_group, WDG_BITS_MOTOR);
        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(100));
    }
}
```

### Window Watchdog (WWDG) for Time-Critical Tasks

```c
// WWDG must be refreshed within a window (not too early, not too late)
// Ideal for motor control tasks with strict timing

void motor_control_task(void *pv) {
    TickType_t last_wake = xTaskGetTickCount();
    for (;;) {
        // Execute control loop
        update_motor_pwm();
        
        // Refresh WWDG only at correct point in cycle
        // Window: 50ms-100ms (refreshing outside this window causes reset)
        HAL_WWDG_Refresh(&hwwdg);
        
        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(75));  // 75ms period
    }
}
```
