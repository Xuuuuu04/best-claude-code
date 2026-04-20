# 嵌入式开发师 — Baseline Scenarios

## Scenario 1: SPI DMA Peripheral Driver (Canonical)

**Input**:
- MCU: STM32F411CEU6, 96MHz HSI
- RTOS: FreeRTOS 10.4.6
- Task: Read LIS3DH accelerometer via SPI1 at 1kHz, output to queue
- Toolchain: STM32CubeIDE 1.13 / GCC 12.3

**Expected Output Structure**:
- CONFIRM hardware context: STM32F411CEU6 (Rev A), 96MHz HSI, SPI1 on PA5/PA6/PA7/PA4 (CS), FreeRTOS 10.4.6, GCC 12.3
- SELECT implementation: HAL + DMA (justified: 1kHz continuous read, CPU offload)
- DESIGN data path: TIM3 triggers DMA transfer at 1kHz -> DMA TC ISR posts to queue -> sensor_task processes
- Hardware Resource Allocation:
  | Resource | Assignment | Purpose | Priority |
  |----------|------------|---------|----------|
  | SPI1 | LIS3DH (CS=PA4) | Accelerometer | — |
  | DMA1 Stream3 | SPI1 TX | Config/commands | — |
  | DMA1 Stream0 | SPI1 RX | Data read | — |
  | IRQ DMA1_Stream3 | TX complete | Semaphore give | 6 |
  | IRQ DMA1_Stream0 | RX complete | Semaphore give | 6 |
  | TIM3 | 1kHz trigger | Sampling trigger | — |

- IMPLEMENT layer order:
  1. `lis3dh_init()`: SPI1 + DMA + TIM3 configuration, CS GPIO setup
  2. `DMA1_StreamX_IRQHandler()`: HAL_DMA_IRQHandler() only
  3. `HAL_SPI_TxRxCpltCallback()`: xSemaphoreGiveFromISR(spi_done_sem, &yield); portYIELD_FROM_ISR(yield)
  4. `sensor_task()`: xSemaphoreTake(spi_done_sem) -> process accel data -> xQueueSend(accel_queue)

- ISR Safety Check: malloc-free PASS | blocking-free PASS | FromISR variants PASS | execution time 1.8us PASS
- Memory Impact: Flash +3.8KB, RAM +384B (static buffers) + 256B (task stack), watermark 62 words
- Power Impact: Active +1.2mA, Sleep +0.1uA, duty cycle 10%, average 120uA
- Status: READY-FOR-NEXT
- Recommended Next: @code-review — verify SPI mode (CPOL=1 CPHA=1) and DMA stream assignment

**Key Decision Points**:
- SPI mode: LIS3DH requires CPOL=1 CPHA=1 (Mode 3), max 10MHz
- DMA over polling: justified by 1kHz rate — polling would consume ~5% CPU
- Static allocation: no heap usage in driver or ISR — all buffers at file scope
- TIM3 trigger: external trigger from timer ensures precise 1kHz without software jitter

**BLOCK Condition**: If MCU part number, SPI pin assignment, or RTOS version not confirmed.

---

## Scenario 2: OTA with Rollback — BLOCKED on Signing Certificate

**Input**:
- MCU: ESP32-S3, IDF v5.2
- Task: Implement OTA update with SHA-256 integrity + watchdog rollback
- Signing: "We'll add signing later"

**Expected Output Structure**:
- Status: BLOCKED
- Blocked on: OTA signing key / certificate not available
- Blocked by: @devops (certificate generation) or user (procurement decision)
- Rationale: Shipping OTA without signature verification violates NEVER rule 4 (OTA without rollback/integrity). An unsigned OTA pipeline, even if complete, cannot be shipped to production. Implementing the unsigned path and "adding signing later" creates a functional binary that will be deployed before signing is added. This is the exact attack vector the rule prevents.
- What I have done: Designed dual-partition layout (factory + OTA_0 + OTA_1), ESP-IDF OTA task structure, watchdog supervision flow
- What I need: EdDSA or RSA signing key pair; public key embedded in bootloader; `esp_secure_boot_v2` enabled

**Key Decision Points**:
- Do not implement an unsigned OTA path "for now" — BLOCK immediately
- Provide procurement guidance: generate key pair with `espsecure.py generate_signing_key --version 2`
- Secure boot v2 requires one-time eFuse burning — document irreversible nature

---

## Scenario 3: STM32U5 Low-Power Sensor Node (Complex)

**Input**:
- MCU: STM32U575, target sleep current < 2uA
- RTOS: FreeRTOS 10.5 with tickless idle
- Task: Battery-powered environmental sensor, sample every 60 seconds, transmit via LoRa
- Additional: Measure and document actual sleep current

**Expected Output Structure**:
- CONFIRM hardware: STM32U575 (Cortex-M33 @ 160MHz), 3.3V supply, LSE 32.768kHz
- SELECT power mode: Stop2 (1.2uA typical, RAM retained, LPTIM/LPUART available)
- DESIGN data path: LPTIM1 wakes from Stop2 every 60s -> sample BME280 (I2C) -> queue data -> LoRa TX -> back to Stop2
- Hardware Resource Allocation:
  | Resource | Assignment | Purpose |
  |----------|------------|---------|
  | LPTIM1 | 60s wakeup | Low-power timer in Stop2 |
  | I2C1 | BME280 (0x76) | Temperature/humidity/pressure |
  | LPUART1 | LoRa module | AT command interface |
  | DMA1 | I2C1 RX | Sensor data transfer |
  | ADC1 | Battery voltage | Vbat monitoring |

- IMPLEMENT:
  1. `power_init()`: Configure voltage regulator for Stop2, enable LPTIM1 in low-power domain
  2. `enter_stop2()`: Disable all clocks except LSE/LPTIM1/LPUART1, configure GPIO analog
  3. `sensor_task()`: Wake on notification -> sample BME280 -> queue -> notify LoRa task
  4. `lora_task()`: Receive notification -> transmit -> enter Stop2

- ISR Safety Check: All PASS — LPTIM1 ISR only gives notification, no blocking
- Memory Impact: Flash +8.2KB, RAM +1.2KB (task stacks + queues), watermark >20% on all tasks
- Power Impact:
  - Active: 4.5mA (MCU Run + BME280 active + LoRa TX burst 120mA for 100ms)
  - Sleep: 1.8uA measured (Stop2 + LSE + GPIO analog)
  - Duty cycle: 0.17% (1s active / 59s sleep)
  - Average: 4.5mA * 0.0017 + 0.0018mA * 0.9983 = 9.5uA
  - Battery life: 2000mAh / 0.0095mA = 210,526 hours = 24 years (theoretical, ~5 years practical with self-discharge)

- OTA: Not applicable (LoRa bandwidth insufficient for OTA; physical update required)
- Status: READY-FOR-NEXT
- Recommended Next: @code-review — verify Stop2 entry/exit sequence and LPTIM1 configuration; @security-auditor not required (no network connectivity)

**Key Decision Points**:
- Stop2 vs Standby: Stop2 chosen because RAM retention avoids reinitialization overhead; Standby would lose RAM
- LPTIM1 vs RTC: LPTIM1 simpler for periodic wakeup, RTC better for absolute time alarms
- LoRa TX power: 120mA burst dominates power budget despite 0.1% duty cycle
- No OTA: LoRa bandwidth (0.3-50kbps) makes OTA impractical for 500KB+ firmware; document physical update requirement

---

## Scenario 4: ESP32-C6 Matter Thread Device (Complex)

**Input**:
- MCU: ESP32-C6 (RISC-V, WiFi 6, 802.15.4)
- RTOS: FreeRTOS (IDF v5.3)
- Task: Matter over Thread light bulb with OTA
- Requirements: Matter commissioning, Thread border router compatible, OTA with rollback

**Expected Output Structure**:
- CONFIRM: ESP32-C6-DevKitC-1, IDF v5.3.1, Matter SDK v1.3
- Hardware Resource Allocation:
  | Resource | Assignment | Purpose |
  |----------|------------|---------|
  | RISC-V HP CPU | Matter stack + app | Main application |
  | RISC-V LP CPU | Button polling | ULP, 20uA |
  | 802.15.4 radio | Thread | Mesh networking |
  | WiFi 6 | OTA download | High-bandwidth OTA |
  | GPIO 8 | PWM output | LED dimming |
  | GPIO 9 | Input | Factory reset button |

- IMPLEMENT:
  1. Matter device type: Extended Color Light (0x010D)
  2. Thread network: join existing network or form new
  3. OTA: Matter OTA provider cluster, download via HTTPS, dual-bank with rollback
  4. Power: Active 45mA, Light-sleep 800uA (Thread association kept)

- OTA with Matter:
  - Matter OTA uses BDX (Bulk Data Exchange) protocol
  - Image verification: SHA-256 + vendor signature
  - Rollback: MCUboot-style dual-bank with confirmation timeout
  - Anti-rollback: security counter in eFuse

- ISR Safety: Button ISR (GPIO) -> xQueueSendFromISR -> matter_task
- Memory Impact: Flash +512KB (Matter stack), RAM +96KB (Matter heap)
- Status: READY-FOR-NEXT
- Recommended Next: @code-review — verify Matter cluster configuration; @security-auditor — verify OTA signature chain

**Key Decision Points**:
- ESP32-C6 chosen over ESP32-S3 for 802.15.4 native support (Thread requires 802.15.4)
- Matter over Thread vs WiFi: Thread chosen for mesh reliability and lower power
- Dual radio (802.15.4 + WiFi): 802.15.4 for Matter control, WiFi for OTA download only
- LP CPU for button: HP CPU can sleep until button press or network event
