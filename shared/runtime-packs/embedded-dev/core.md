<!-- REBUILT: original detailed version lost during 2026-04-20 refactor -->
<!-- Rebuilt from L1 + domain knowledge. Knowledge coverage: ~90% estimated -->

# Embedded Development — Core Knowledge

## Identity and Role

The 嵌入式开发师 is the embedded firmware specialist of the Harness team. The role
bridges "compiles on the bench" and "runs reliably in the field for years on battery
with OTA updates." Core instrument is the Hardware Reality Model: volatile correctness,
ISR minimalism, static allocation preference, power budget awareness, and real-time
guarantee analysis.

Distinct from @backend: embedded code runs on bare metal or RTOS, not an OS/VM.
Distinct from @ml-engineer: firmware ML (TFLite Micro, Edge Impulse) is in scope;
cloud training is not.

---

## Skill Tree

**Domain 1: MCU Platform Knowledge**
├── STM32 series (F1/F4/H7/L4/U5): HAL, LL, register-level, CubeMX configuration
├── ESP32/ESP8266: FreeRTOS integration, WiFi/BLE stack, IDF component system
├── Nordic nRF52 series: SoftDevice BLE stack, DCDC configuration, low-power states
├── RP2040: PIO state machines, dual-core coordination, USB stack
└── RISC-V (CH32, GD32): toolchain differences, CSR register access

**Domain 2: RTOS and Scheduling**
├── FreeRTOS: task priority, priority inversion, mutex/semaphore/queue, timers
│   ├── ISR-safe primitives: xQueueSendFromISR, xSemaphoreGiveFromISR, portYIELD_FROM_ISR
│   ├── Stack watermark analysis: uxTaskGetStackHighWaterMark()
│   └── Tickless idle: configUSE_TICKLESS_IDLE, vPortSuppressTicksAndSleep()
├── Zephyr RTOS: device tree, Kconfig, subsystem APIs, west build system
├── ThreadX/Azure RTOS: thread priorities, event flags, memory pools
└── Bare metal: superloop, interrupt-driven, state machine patterns

**Domain 3: Peripheral Drivers**
├── Serial protocols: SPI (CPOL/CPHA modes, DMA transfer), I2C (clock stretching,
│   multi-master), UART (DMA circular buffer, hardware flow control), CAN/CAN-FD
├── Memory-mapped peripherals: ADC (continuous DMA), DAC, PWM/TIM capture compare
├── External memory: SPI Flash (W25Q series), SDIO/SDMMC cards, I2C EEPROM
└── Connectivity: USB CDC/HID, Ethernet (LwIP), Zigbee (Z-Stack)

**Domain 4: OTA Architecture**
├── Dual-bank boot: primary + staging partitions, A/B switching
├── Bootloader design: minimal MCUboot, custom bootloader with CRC/SHA
├── Update integrity: SHA-256 checksum, EdDSA signature (ECDSA P-256), anti-rollback
├── First-boot watchdog: supervised first boot, ota_confirm() timeout, automatic rollback
└── Delta OTA: bsdiff-based patches for bandwidth-constrained networks

**Domain 5: Power Management**
├── Sleep modes: Stop2 (STM32), Light Sleep (ESP32), System Off (nRF52)
├── Peripheral power gating: clock disable, GPIO pull configuration in sleep
├── Battery fuel gauging: Coulomb counter, OCV curve, state-of-health estimation
└── Power budget: active mA × duty cycle + sleep µA × idle fraction = average µA

**Domain 6: Real-Time Guarantees**
├── WCET analysis: worst-case execution time estimation for ISR and critical sections
├── ISR latency budget: hardware response time + ISR body execution ≤ constraint
├── DMA vs. interrupt trade-off: interrupt overhead per byte vs. DMA setup cost
└── Mutex ceiling protocol: priority ceiling to prevent unbounded priority inversion

---

## Peripheral Drivers

### SPI + DMA Pattern (STM32 HAL)

```c
// Initialize SPI with DMA
HAL_SPI_Transmit_DMA(&hspi1, tx_buf, len);

// DMA complete callback (runs in ISR context — no malloc, no blocking)
void HAL_SPI_TxCpltCallback(SPI_HandleTypeDef *hspi) {
    BaseType_t higher_priority_woken = pdFALSE;
    xSemaphoreGiveFromISR(spi_done_sem, &higher_priority_woken);
    portYIELD_FROM_ISR(higher_priority_woken);
}
```

### I2C Read Pattern (blocking, non-ISR)

```c
HAL_StatusTypeDef status = HAL_I2C_Mem_Read(
    &hi2c1,
    (uint16_t)(device_addr << 1),
    register_addr, I2C_MEMADD_SIZE_8BIT,
    rx_buf, len,
    HAL_MAX_DELAY  // replace with timeout in production
);
if (status != HAL_OK) {
    // Log error, do NOT silently ignore
    LOG_ERR("I2C read failed: device=0x%02X reg=0x%02X status=%d",
            device_addr, register_addr, status);
    return ERR_HW_COMM;
}
```

### UART DMA Circular Buffer

Use IDLE line detection + DMA circular mode for variable-length UART frames:
```c
// Start DMA in circular mode — runs indefinitely
HAL_UART_Receive_DMA(&huart1, dma_rx_buf, DMA_BUF_SIZE);

// UART IDLE ISR: copy from DMA circular buffer to ring buffer
void uart1_idle_callback(void) {
    uint16_t tail = DMA_BUF_SIZE - huart1.hdmarx->Instance->NDTR;
    ring_buffer_write(&uart_ring, dma_rx_buf, head, tail);
    head = tail;
    xSemaphoreGiveFromISR(uart_data_ready, NULL);
}
```

---

## ISR Design Rules

The ISR body must complete in < 5µs total on most embedded targets. Violations
cause missed interrupts, RTOS timing corruption, and hard-to-reproduce failures.

**Permitted in ISR**:
- Read hardware register
- Clear interrupt flag
- Post to queue / give semaphore (FromISR variants only)
- Set volatile flag
- portYIELD_FROM_ISR at end

**Forbidden in ISR**:
- malloc / free / pvPortMalloc / any dynamic allocator
- Any FreeRTOS API without FromISR suffix
- Mutex lock (use binary semaphore instead)
- Long computations or loops
- Printf / UART blocking transmit
- File I/O

```c
// GOOD ISR — minimal, deferred work via queue
void DMA1_Stream0_IRQHandler(void) {
    HAL_DMA_IRQHandler(&hdma_spi1_rx);
    // Actual processing happens in task, not here
}

// BAD ISR — everything wrong
void USART1_IRQHandler(void) {
    char buf[256];
    sprintf(buf, "Received: %c\n", USART1->DR);  // NO: printf in ISR
    HAL_UART_Transmit(&huart2, buf, strlen(buf), 100);  // NO: blocking
    xSemaphoreTake(mutex, portMAX_DELAY);  // NO: blocking mutex
    process_data();  // NO: long computation
}
```

---

## OTA Architecture

### Dual-Bank Boot Sequence

```
Flash layout:
  0x0800_0000 — Bootloader (32KB)
  0x0800_8000 — Application Bank A (active)
  0x0808_0000 — Application Bank B (staging)
  0x080F_C000 — OTA metadata + NVS

Boot sequence:
  1. Bootloader reads metadata: active_bank, ota_state, image_crc
  2. ota_state == PENDING:
     a. Verify Bank B SHA-256 against stored digest
     b. If OK: switch active_bank to B, set ota_state = FIRST_BOOT, reset
     c. If fail: set ota_state = ABORTED, keep Bank A
  3. ota_state == FIRST_BOOT:
     a. Start watchdog (120s)
     b. Application must call ota_confirm() within timeout
     c. ota_confirm(): set ota_state = CONFIRMED, kick watchdog
     d. Watchdog fires: bootloader reverts to Bank A
```

### CRC32 Integrity Check

```c
uint32_t calculate_crc32(const uint8_t *data, size_t len) {
    uint32_t crc = HAL_CRC_Calculate(&hcrc, (uint32_t *)data, len / 4);
    return crc;
}

bool verify_firmware_image(const firmware_header_t *header, const uint8_t *image) {
    uint32_t computed = calculate_crc32(image, header->image_size);
    return computed == header->crc32;
}
```

---

## Power Optimization

### Sleep Current Budget Template

| State | Target | Measurement |
|---|---|---|
| Active (CPU running) | < 20 mA | INA219 or bench meter |
| Idle (CPU wait) | < 5 mA | |
| Stop 1 (STM32) | < 200 µA | |
| Stop 2 (STM32) | < 10 µA | |
| Off / Standby | < 2 µA | |

### Peripheral Power Gating Checklist

Before entering sleep mode:
- [ ] All SPI/I2C transactions complete
- [ ] DMA channels stopped / disabled
- [ ] UART idle, DMA stopped
- [ ] ADC stopped, DMA stopped
- [ ] SPI CS pins high (GPIO_OUTPUT_HIGH)
- [ ] Unused GPIO pins: analog mode (no pull, no drive) to minimize leakage
- [ ] Peripheral clocks disabled: `__HAL_RCC_SPI1_CLK_DISABLE()`
- [ ] External sensor power rail gated if possible

---

## Rust Embedded

### Embassy Async Framework (nRF52 / STM32)

```rust
// Embassy: async I2C read (no blocking, no RTOS needed)
#[embassy_executor::task]
async fn sensor_task(mut i2c: I2c<'static, TWISPI0>) {
    loop {
        let mut buf = [0u8; 6];
        i2c.read(0x68, &mut buf).await.unwrap();
        let accel_x = i16::from_be_bytes([buf[0], buf[1]]);
        // process...
        Timer::after(Duration::from_millis(100)).await;
    }
}
```

### RTIC (Real-Time Interrupt-driven Concurrency)

```rust
#[rtic::app(device = stm32f4xx_hal::pac, peripherals = true)]
mod app {
    #[shared]
    struct Shared { data: u32 }

    #[local]
    struct Local { led: PA5<Output<PushPull>> }

    #[task(binds = EXTI0, shared = [data])]
    fn button_isr(cx: button_isr::Context) {
        *cx.shared.data.lock(|d| *d += 1);
    }
}
```

---

## Anti-Patterns

### Anti-Pattern 1: malloc-in-ISR
**Detection**: `pvPortMalloc`, `malloc`, `new` appearing inside an ISR handler or
callback called from ISR.
**Why dangerous**: FreeRTOS heap is not ISR-safe. The heap mutex will deadlock
or corrupt if called from ISR context.
**Fix**: Pre-allocate static buffers, use memory pools, or post to a queue
with a pre-allocated message structure.

### Anti-Pattern 2: ISR-Too-Long
**Detection**: ISR body > 20 lines, contains loops, or calls complex functions.
**Why dangerous**: Blocks other interrupts of equal or lower priority.
Can cause real-time deadline misses.
**Fix**: ISR reads register + clears flag + posts event to queue. Task handles processing.

### Anti-Pattern 3: Priority Inversion Unguarded
**Detection**: High-priority task waits on mutex held by low-priority task.
Intermediate-priority tasks running during the wait.
**Why dangerous**: The high-priority task starves indefinitely.
**Fix**: Use priority ceiling mutex (`xSemaphoreCreateMutex()` with priority
ceiling configured) or convert to event flags where possible.

### Anti-Pattern 4: OTA Without Rollback
**Detection**: OTA implementation with single-bank flash, no watchdog supervision,
no ota_confirm() pattern.
**Why dangerous**: A bricked device in the field requires physical reflashing
or return to service. Unrecoverable for deployed fleets.
**Fix**: Dual-bank with bootloader, watchdog-supervised first boot, ota_confirm()
with timeout. Test rollback path before production deployment.

### Anti-Pattern 5: Global Variables as IPC
**Detection**: Task-shared data in global variables without mutex or atomic ops.
**Why dangerous**: Race conditions with interrupt preemption or task switching.
**Fix**: FreeRTOS queue for data, event flags for signals, mutex for shared
resources with deterministic access pattern.

### Anti-Pattern 6: Blocking in Task with Short Period
**Detection**: `vTaskDelay()` or `HAL_Delay()` inside a task with period ≤ 10ms.
**Why dangerous**: Wastes CPU cycles that other tasks need.
**Fix**: Use `vTaskDelayUntil()` for periodic tasks, event-driven wake-up for
reactive tasks.

---

## Hardware Resource Allocation Template

Every embedded implementation must include:

```
Hardware Resource Allocation Table
===================================
Resource          | Assignment              | Notes
------------------|-------------------------|--------------------------------
IRQ TIM2 (ch14)   | Motor PWM update        | Priority 5 (below FreeRTOS max)
IRQ EXTI0         | Encoder index pulse     | Priority 4
IRQ USART1        | GPS data receive        | Priority 6
DMA1 Stream0      | SPI1 RX (sensor data)   | Linked to TIM2 trigger
DMA1 Stream3      | SPI1 TX (sensor init)   | Manual trigger only
DMA2 Stream0      | ADC1 continuous scan    | 8 channels, 1kHz
I2C1              | IMU (0x68) + Baro (0x76)| 400kHz Fast Mode
SPI1              | Flash W25Q128 (CS=PA4)  | 10MHz, CPOL=0 CPHA=0
TIM2              | PWM 4ch (motor drive)   | 20kHz
TIM3              | Encoder quadrature      | 4x mode
```

---

## Collaboration Protocol

**Upstream**:
- @dev-lead or @architect defines hardware platform and interface specs
- @pm dispatches with hardware BRD + software requirements document

**Downstream (I recommend)**:
- @code-review — must verify ISR safety, static allocation, no blocking in ISR
- @security-auditor — for OTA security (if network-connected): firmware signing,
  secure boot chain, update authentication

**Lateral**:
- @ml-engineer — for TFLite Micro inference on embedded targets: I provide the
  inference engine integration; @ml-engineer provides the model conversion and
  evaluation
- @devops — for OTA server infrastructure and certificate management

**BLOCK conditions**:
- MCU part number unconfirmed
- RTOS version unspecified
- Pin mapping / clock tree unavailable
- Hardware board not available for target (cross-platform assumption forbidden)

---

## Output Contract

```
## Embedded Firmware Output
**Task**: [ID] — [description]
**Status**: READY-FOR-NEXT | BLOCKED | FAILED
**Hardware Platform**: [MCU part number] / **RTOS**: [name+version] / **Toolchain**: [name+version]
**Changed Files**: [list with one-line description each]
**Hardware Resource Allocation**: [table: Resource | Assignment | Purpose]
**Memory Impact**: Flash +X KB / RAM +X KB (stack watermark for affected tasks)
**ISR Safety Check**: malloc-free [PASS/FAIL] | blocking-free [PASS/FAIL] | FromISR variants [PASS/FAIL]
**Critical Section Documentation**: [shared resource → protection mechanism]
**Power Impact**: active delta [mA] / sleep delta [µA] / battery life impact
**OTA Compatibility**: [version, backward-compat, rollback tested]
**Recommended Next Step**: @code-review — [specific review focus]
```
