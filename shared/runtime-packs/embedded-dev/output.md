# Embedded Dev — Output Contract Reference

## Standard Output Format

```
## Embedded Firmware Output

**Task**: [ID] — [one-sentence description]
**Status**: READY-FOR-NEXT | BLOCKED | FAILED
**Hardware Platform**: [MCU part number + revision] / **RTOS**: [name+version] / **Toolchain**: [name+version]

### Changed Files
| File | Description |
|------|-------------|
| `drivers/sensor_xyz.c` | SPI driver for XYZ sensor, DMA-based transfer |
| `drivers/sensor_xyz.h` | Public API: init, read, configure |
| `tasks/sensor_task.c` | FreeRTOS task, 1kHz sampling, queue output |

### Hardware Resource Allocation
| Resource | Assignment | Purpose | Priority |
|----------|------------|---------|----------|
| IRQ TIM2 | Motor PWM update | 20kHz PWM generation | 5 |
| IRQ EXTI0 | Encoder index pulse | Position reference | 4 |
| IRQ USART1 | GPS data receive | NMEA frame parsing | 6 |
| DMA1 Stream0 | SPI1 RX | Sensor data transfer | — |
| DMA1 Stream3 | SPI1 TX | Sensor init/config | — |
| I2C1 | IMU (0x68) + Baro (0x76) | 400kHz Fast Mode | — |
| SPI1 | Flash W25Q128 (CS=PA4) | 10MHz, Mode 0 | — |

### Memory Impact
- Flash: +4.2 KB (driver code + data tables)
- RAM: +512 B (static buffers) + 256 B (task stack)
- Stack watermark (sensor_task): 48 words remaining (of 512 allocated) — 9% margin, ACCEPTABLE

### ISR Safety Check
| Check | Result | Notes |
|-------|--------|-------|
| malloc-free | PASS | All static allocation |
| blocking-free | PASS | No mutex/semaphore take in ISR |
| FromISR variants | PASS | xQueueSendFromISR used exclusively |
| Execution time | PASS | 2.3us measured (DWT->CYCCNT), target < 5us |

### Critical Section Documentation
| Shared Resource | Protection Mechanism | ISR/Task |
|-----------------|---------------------|----------|
| SPI1 bus | xSemaphoreCreateMutex() | Task only |
| Sensor data buffer | xQueue (length 8) | ISR -> Task |
| Config flags | taskENTER_CRITICAL() | Both |

### Power Impact
- Active current delta: +2.1 mA (SPI Flash read at 10MHz)
- Sleep current delta: +0.3 uA (SPI Flash standby, CS high)
- Duty cycle: 0.1% (1KB read every 10 seconds)
- Average impact: 2.4 uA
- Battery life impact: negligible on 2000mAh cell

### OTA Compatibility
- Version: 1.2.3
- Backward compatible: Yes (no schema changes)
- Rollback tested: Yes — kill-before-confirm verified automatic rollback

### Recommended Next Step
@code-review — verify ISR safety, DMA configuration, and stack watermark adequacy
```

## BLOCKED Output Format

```
## Embedded Firmware Output

**Task**: [ID] — [description]
**Status**: BLOCKED

**Blocked on**: [specific missing item]
**Blocked by**: [@role or user]
**Rationale**: [why this blocks implementation]

**What I have done**: [completed work despite block]
**What I need**: [specific unblock condition]
```

## Filled Example — SPI DMA Driver

```
## Embedded Firmware Output

**Task**: T-042 — LIS3DH accelerometer driver via SPI1 DMA
**Status**: READY-FOR-NEXT
**Hardware Platform**: STM32F411CEU6 (Rev A) / **RTOS**: FreeRTOS 10.4.6 / **Toolchain**: GCC 12.3 (STM32CubeIDE 1.13)

### Changed Files
| File | Description |
|------|-------------|
| `drivers/lis3dh.c` | SPI1 DMA driver, CPOL=1 CPHA=1, 10MHz max |
| `drivers/lis3dh.h` | Public API: lis3dh_init(), lis3dh_read_accel(), lis3dh_set_odr() |
| `tasks/sensor_task.c` | 1kHz sampling task, outputs to accel_queue |

### Hardware Resource Allocation
| Resource | Assignment | Purpose | Priority |
|----------|------------|---------|----------|
| IRQ DMA1_Stream3 | SPI1 TX complete | DMA TC callback | 6 |
| IRQ DMA1_Stream0 | SPI1 RX complete | DMA TC callback | 6 |
| SPI1 | LIS3DH (CS=PA4) | Accelerometer communication | — |
| TIM3 | 1kHz trigger | Sensor sampling trigger | — |

### Memory Impact
- Flash: +3.8 KB
- RAM: +384 B (static tx/rx buffers 128B each) + 256 B (task stack)
- Stack watermark: 62 words remaining (of 512) — 12% margin, ACCEPTABLE

### ISR Safety Check
| Check | Result |
|-------|--------|
| malloc-free | PASS |
| blocking-free | PASS |
| FromISR variants | PASS |
| Execution time | PASS — 1.8us measured |

### Critical Section Documentation
| Shared Resource | Protection |
|-----------------|------------|
| SPI1 device | Mutex (task level only) |
| accel_data | Queue (ISR -> Task) |

### Power Impact
- Active: +1.2 mA (SPI1 + LIS3DH active)
- Sleep: +0.1 uA (LIS3DH power-down mode)
- Duty cycle: 10% (1ms active / 9ms sleep per sample)
- Average: 120 uA

### OTA Compatibility
- Not applicable (driver only, no OTA changes)

### Recommended Next Step
@code-review — verify SPI mode configuration and DMA stream assignment
```
