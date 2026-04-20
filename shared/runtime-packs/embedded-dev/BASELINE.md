# Embedded Dev — Baseline Scenarios

## Scenario 1: SPI DMA Peripheral Driver (Simple Canonical)

**Input**:
- MCU: STM32F411CEU6, 96MHz HSI
- RTOS: FreeRTOS 10.4
- Task: Read LIS3DH accelerometer via SPI1 at 1kHz, output to queue
- Toolchain: STM32CubeIDE 1.13 / GCC 12.3

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Changed files: `drivers/lis3dh.c`, `drivers/lis3dh.h`, `tasks/sensor_task.c`
- Hardware Resource Allocation: SPI1, DMA1 Stream0/Stream3, IRQ entries listed
- ISR Safety Check: all PASS
- Memory Impact: Flash +4KB, RAM +512B (stack watermark noted)
- Power Impact: N/A (no sleep mode change)
- Recommended Next: @code-review — verify ISR safety and DMA configuration

**Key Decision Points**:
- SPI mode selection: DMA transfer preferred for 1kHz continuous read
- ISR callback: xQueueSendFromISR only, portYIELD_FROM_ISR at end
- Static allocation: no heap usage in driver or ISR

**BLOCK Condition**: If MCU part number, SPI pin assignment, or RTOS version not confirmed.

---

## Scenario 2: OTA with Rollback (Blocked on Signing Cert)

**Input**:
- MCU: ESP32-S3, IDF v5.2
- Task: Implement OTA update with SHA-256 integrity + watchdog rollback
- Signing: "We'll add signing later"

**Expected Output Structure**:
- Status: BLOCKED
- Blocked on: OTA signing key / certificate not available
- Blocked by: @devops (certificate generation) or user (procurement decision)
- Rationale: Shipping OTA without signature verification violates NEVER rule 4.
  An unsigned OTA pipeline, even if complete, cannot be shipped to production.
  Implementing the unsigned path and "adding signing later" creates a functional
  binary that will be deployed before signing is added. This is the exact attack
  vector the rule prevents.
- What I have done: Designed dual-partition layout, MCUboot configuration
- What I need: EdDSA signing key + verification public key embedded in bootloader

**Key Decision Points**:
- Do not implement an unsigned OTA path "for now" — BLOCK immediately
- Provide procurement guidance for Apple Developer ID or self-signed EdDSA cert

---

## Scenario 3: FreeRTOS Priority Inversion + Power Budget (Complex)

**Input**:
- MCU: STM32L476, target sleep current < 5µA
- RTOS: FreeRTOS 10.5 with configUSE_MUTEXES=1
- Issue: High-priority motor control task starving due to suspected priority inversion
  with SPI mutex held by sensor task
- Additional: Battery-powered device, sleep current measurement required

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Changed files: `rtos/mutex_config.c`, `tasks/motor_task.c`, `power/sleep.c`
- Hardware Resource Allocation: Full table with TIM, SPI, IRQ priorities
- ISR Safety Check: PASS on all
- Memory Impact: RAM +0 (configuration change only)
- Power Impact: Active delta -2mA (removed unnecessary peripheral keep-alive)
  Sleep delta: measured -3µA (peripheral clock gating added), estimated 8% longer
  battery life at 40mA average active / 2µA sleep with 1% duty cycle
- Critical Section Documentation: SPI1 → xSemaphoreCreateMutex() with priority
  ceiling = motor_task priority (configMAX_PRIORITIES - 2)
- OTA: Not applicable this task
- Recommended Next: @code-review — verify priority ceiling configuration;
  @security-auditor not required (no network connectivity change)
