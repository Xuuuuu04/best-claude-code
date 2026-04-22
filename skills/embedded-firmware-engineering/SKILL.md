---
name: embedded-firmware-engineering
description: Embedded firmware engineering methodology for the Harness team. Covers MCU platforms (STM32, ESP32, nRF5x, RP2350, RISC-V), RTOS integration (FreeRTOS, Zephyr, ThreadX), peripheral drivers (SPI/I2C/UART/CAN/DMA, ADC, GPIO), OTA architecture (dual-bank, MCUboot, rollback, anti-rollback), power management (sleep modes, clock gating, battery budgeting), and real-time guarantee analysis (WCET, ISR latency, priority inversion prevention). Loaded by @embedded-dev via skills: frontmatter.
type: skill
---

# Embedded Firmware Engineering Skill

## 1. MCU Platforms

**STM32**: F4 (Cortex-M4, DSP+FPU, DMA circular mode), H5 (Cortex-M33, TrustZone, FD-CAN), U5 (ultra-low power, LPDMA, AES), G0 (cost-optimized, USB PD).

**ESP32**: Dual-core Xtensa (WiFi/BLE), ESP32-C6 (RISC-V, WiFi 6, 802.15.4), ESP32-S3 (AI vector instructions, USB OTG). ESP-IDF: menuconfig, partition table, secure boot v2, flash encryption.

**Nordic nRF5x**: nRF52840 (Cortex-M4, BLE 5.2, USB), nRF5340 (dual-core, TrustZone, LE Audio). SoftDevice: S140 (central+peripheral), S113 (peripheral only).

**RP2040/RP2350**: Dual-core Cortex-M0+ / M33, PIO state machines, USB 1.1.

**RISC-V**: CH32V307 (QingKe V4F, USB, Ethernet), GD32VF103 (Bumblebee core).

## 2. RTOS and Scheduling

**FreeRTOS**:
- `xTaskCreateStatic` preferred over `xTaskCreate` (deterministic, no heap fragmentation)
- ISR-safe primitives: `xQueueSendFromISR`, `xSemaphoreGiveFromISR`, `xEventGroupSetBitsFromISR`
- Task notifications: `ulTaskNotifyTake()`, `xTaskNotifyGiveFromISR()` — lightweight, faster, less RAM than semaphores
- Tickless idle: `configUSE_TICKLESS_IDLE`, deep sleep integration
- Heap selection: heap_1 (static only), heap_4 (coalescing), heap_5 (multiple regions)

**Zephyr**: Device tree (`.dts`/`.overlay`), Kconfig, work queues (`k_work_submit()`), memory slabs/pools.

**ThreadX**: Thread priorities with preemption threshold, event flags.

## 3. Peripheral Drivers

**Serial protocols**: SPI (CPOL/CPHA, DMA transfer), I2C (clock stretching, multi-master, bus recovery), UART (DMA circular buffer, IDLE line detection), CAN/CAN-FD (frame filtering, dispatch table).

**Memory-mapped**: ADC (continuous DMA scan, oversampling), DAC (DMA wave generation), Timer/PWM (capture/compare, encoder mode), GPIO (interrupt config, debouncing).

**External memory**: SPI Flash (W25Q, QSPI, XIP), SD/MMC (SDIO), EEPROM (page write, write polling).

**Connectivity**: USB CDC (bulk endpoints, enumeration), BLE (GATT services, advertising), Ethernet (LwIP, MAC, PHY).

## 4. OTA Architecture

**Bootloader design**: MCUboot (multi-platform, image signing, swap/move modes), ESP-IDF OTA (native partition API, https_ota), custom bootloader (vector table relocation).

**Update integrity**: SHA-256 digest verification, EdDSA P-256 asymmetric signature, `imgtool` signing workflow.

**Rollback mechanism**: Watchdog-supervised first boot (`ota_confirm()` timeout), dual-bank atomic switch, automatic rollback on failed confirmation.

**Anti-rollback**: Security counter in OTP/efuse, monotonic version enforcement.

**Rollback testing checklist**: unsigned reject, old version reject, kill-before-confirm, power-loss mid-write.

**Delta OTA**: `bsdiff`/`janpatch` for binary diff, RAM-efficient streaming, source version hash verification.

## 5. Power Management

**Sleep modes**: STM32 (Sleep, Stop1, Stop2, Standby), ESP32 (Active, Modem-sleep, Light-sleep, Deep-sleep), nRF52 (System ON, System OFF).

**Peripheral power gating**: `__HAL_RCC_PERIPH_CLK_DISABLE()` before sleep, GPIO sleep config (analog mode for unused pins), external sensor rail control.

**Battery management**: Coulomb counter, OCV curve lookup, SoH estimation.

**Power budget calculation**: `active_mA * duty_cycle + sleep_uA * (1 - duty_cycle) = average_uA`

**Low-power patterns**: Event-driven (sleep until interrupt), batch processing, sensor duty cycling.

## 6. Real-Time Guarantees

**WCET analysis**: Instruction counting (`DWT->CYCCNT`), worst-case branch path, cache miss penalty.

**ISR latency budget**: Hardware latency (12-68 cycles on Cortex-M) + software latency (ISR body + context switch).

**DMA vs interrupt trade-off**: Per-byte interrupt overhead (~50 cycles/byte) vs DMA setup cost (~200 cycles, amortized over transfer size).

**Priority inversion prevention**: Priority inheritance (`configUSE_MUTEXES=1`) or priority ceiling (highest task priority that uses resource).

## 7. ISR Safety Discipline

Every ISR must pass the 5-point check:
1. No malloc/free/pvPortMalloc — static allocation only
2. No blocking primitives — no `xSemaphoreTake` with timeout
3. FromISR variants only — `xQueueSendFromISR`, not `xQueueSend`
4. `portYIELD_FROM_ISR` at end — if higher-priority task was woken
5. Execution time < 5us — measured with `DWT->CYCCNT` or logic analyzer

## 8. Static Allocation Preference

BAD: `xTaskCreate()` with dynamic stack — heap fragmentation risk
GOOD: `xTaskCreateStatic()` with pre-allocated stack and TCB — deterministic

BAD: `pvPortMalloc()` in initialization — heap state unpredictable
GOOD: Static buffers at file scope — size known at compile time

## 9. OTA Safety Contract

1. Image integrity verified before activation (SHA-256 or signature)
2. First boot supervised by watchdog with confirmation timeout
3. Rollback path tested in staging before production
4. Anti-rollback counter prevents downgrade to vulnerable versions
5. Power-loss during write does not corrupt bootloader or both banks
