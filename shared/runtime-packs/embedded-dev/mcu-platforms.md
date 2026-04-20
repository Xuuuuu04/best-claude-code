# Embedded Dev — MCU Platform Deep Dive

## STM32 Series

### STM32H5 (Cortex-M33, TrustZone)

The STM32H5 is STMicroelectronics' mid-range security-focused MCU, featuring Cortex-M33 with TrustZone, secure boot, and hardware crypto.

**Key specifications**:
- Core: Cortex-M33 @ 250 MHz, MPU, TrustZone
- Security: Secure boot, OTFDEC (on-the-fly decryption), AES/GHASH hardware
- Power: Run 93 uA/MHz, Stop2 2.5 uA, Standby 0.12 uA
- Flash: 128KB-2MB dual-bank with RDP (readout protection)

**Clock configuration**:
```c
// STM32H5 PLL configuration for 250MHz
// HSE = 8MHz, PLL1M = 1, PLL1N = 125, PLL1P = 4
// VCO = 8 * 125 = 1000MHz, SYSCLK = 1000 / 4 = 250MHz
RCC_OscInitTypeDef RCC_OscInitStruct = {0};
RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
RCC_OscInitStruct.HSEState = RCC_HSE_ON;
RCC_OscInitStruct.PLL1.PLLState = RCC_PLL_ON;
RCC_OscInitStruct.PLL1.PLLSource = RCC_PLLSOURCE_HSE;
RCC_OscInitStruct.PLL1.PLLM = 1;
RCC_OscInitStruct.PLL1.PLLN = 125;
RCC_OscInitStruct.PLL1.PLLP = 4;
HAL_RCC_OscConfig(&RCC_OscInitStruct);
```

**TrustZone boot**:
```c
// Secure world entry point
void SECURE_EntryPoint(void) {
    // Configure SAU (Security Attribution Unit)
    // Non-secure callable veneers for secure services
    // Initialize secure peripherals
}
```

### STM32U5 (Ultra-Low Power)

**Key specifications**:
- Core: Cortex-M33 @ 160 MHz
- Power: 19 uA/MHz in Run, 1.8 uA in Stop2, 0.02 uA in Standby
- Features: LPDMA (low-power DMA), AES accelerator, PKA (public key accelerator)

**Low-power DMA (LPDMA) usage**:
```c
// LPDMA can operate in Stop2 mode — critical for sensor sampling while CPU sleeps
// Configure LPDMA channel for ADC transfer
LPDMA_Channel_TypeDef *lpdma_ch = LPDMA1_Channel0;
lpdma_ch->CCR |= LPDMA_CCR_EN;
// LPDMA continues in Stop2, wakes CPU only when threshold reached
```

---

## ESP32 Family

### ESP32-C6 (RISC-V, WiFi 6, 802.15.4)

**Key specifications**:
- Core: RISC-V @ 160 MHz (HP CPU) + RISC-V @ 20 MHz (LP CPU)
- Wireless: WiFi 6 (802.11ax), BLE 5.3, 802.15.4 (Zigbee/Thread/Matter)
- Memory: 512KB SRAM, 4MB+ external flash
- Security: Secure boot v2, flash encryption, HMAC/JTAG disable

**Power modes**:
| Mode | CPU | WiFi/BLE | Current |
|------|-----|----------|---------|
| Active | HP on | TX/RX | 240 mA |
| Modem-sleep | HP on | Association kept | 20 mA |
| Light-sleep | HP paused | Association kept | 800 uA |
| Deep-sleep | HP off | Off | 7 uA |

**LP CPU for sensor polling**:
```c
// ESP32-C6 low-power CPU can sample sensors while HP CPU sleeps
// ULP RISC-V program:
ulp_lp_core_load_binary(ulp_bin_start, (ulp_bin_end - ulp_bin_start));
ulp_lp_core_run();
// LP CPU wakes HP CPU via interrupt when threshold exceeded
```

### ESP32-S3 (AI Acceleration)

**Key specifications**:
- Core: Xtensa LX7 dual-core @ 240 MHz
- AI: Vector instructions (SIMD), 512KB SRAM + 384KB ROM
- USB: USB OTG (full-speed), USB Serial/JTAG controller
- Display: LCD interface, camera interface

**Secure boot v2 + flash encryption**:
```bash
# Generate signing key
espsecure.py generate_signing_key --version 2 secure_boot_signing_key.pem

# Enable secure boot and flash encryption in menuconfig
# Security features -> Enable secure boot in bootloader
# Security features -> Enable flash encryption on boot

# Burn eFuses (one-time, irreversible)
espefuse.py --port /dev/ttyUSB0 burn_key secure_boot_v2 secure_boot_signing_key.pem
```

---

## Nordic nRF5x

### nRF52840

**Key specifications**:
- Core: Cortex-M4 @ 64 MHz with FPU
- Radio: BLE 5.2, 802.15.4, ANT, 2.4GHz proprietary
- Memory: 1MB Flash, 256KB RAM
- Peripherals: USB 2.0 FS, QSPI, NFC-A tag
- Power: 1.7V-5.5V operation, 4.6mA TX @ 0dBm

**SoftDevice architecture**:
```c
// SoftDevice is a pre-compiled binary that occupies the bottom of flash
// Application runs above SoftDevice, calls BLE API via supervisor calls

// Initialize SoftDevice S140 (central + peripheral)
ble_stack_init();

// GATT service definition
BLE_UUID_DEF(service_uuid, 0x1234);
ble_gatts_attr_t attr_char_value = {
    .p_uuid = &char_uuid,
    .p_attr_md = &attr_md,
    .init_len = sizeof(uint16_t),
    .max_len = sizeof(uint16_t),
    .p_value = (uint8_t *)&initial_value
};
```

**DCDC configuration for low power**:
```c
// Enable DCDC converter for both REG0 and REG1
// Reduces current consumption by ~30% compared to LDO mode
sd_power_dcdc_mode_set(NRF_POWER_DCDC_ENABLE);
```

---

## Raspberry Pi Silicon

### RP2350

**Key specifications**:
- Core: Dual Cortex-M33 (optional) or dual Hazard3 RISC-V
- Memory: 520KB SRAM, external QSPI flash (up to 16MB)
- Peripherals: HSTX (high-speed serial), enhanced PIO, USB 1.1
- Security: ARM TrustZone or RISC-V PMP, OTP (one-time programmable) memory

**PIO (Programmable I/O) — enhanced in RP2350**:
```c
// RP2350 PIO can drive HSTX for high-speed interfaces
// PIO program for custom protocol:
.program custom_spi
    pull block          ; Get data from TX FIFO
    out pins, 8         ; Shift 8 bits to pins
    jmp !osre, custom_spi ; Loop if more data

// C setup:
PIO pio = pio0;
uint sm = 0;
uint offset = pio_add_program(pio, &custom_spi_program);
custom_spi_program_init(pio, sm, offset, DATA_PIN, CLK_PIN);
```

**Dual-core coordination**:
```c
// RP2350 Core 0 and Core 1 share SRAM but have separate NVIC
// Use hardware spinlocks for critical sections
uint32_t spinlock_id = 0;
spin_lock_unsafe_blocking(spinlock_id);
// Critical section: access shared resource
spin_unlock_unsafe(spinlock_id, save);
```

---

## RISC-V

### CH32V307 (WCH)

**Key specifications**:
- Core: QingKe V4F (RISC-V) @ 144 MHz, single-precision FPU
- Memory: 128KB Flash, 32KB SRAM
- Peripherals: USB OTG, Ethernet MAC, 8 UARTs, 2 CAN
- Cost: ~$1.50 in volume — STM32F103 pin-compatible

**Interrupt handling (WCH fast interrupt)**:
```c
// CH32V307 has hardware vectored interrupts (no software dispatch)
// Interrupt vector table in startup code:
__attribute__((section(".vector"))) void (* const vector_table[])(void) = {
    [TIM2_IRQn] = tim2_isr,
    [USART1_IRQn] = usart1_isr,
};

// ISR definition:
void tim2_isr(void) __attribute__((interrupt));
void tim2_isr(void) {
    TIM2->INTFR &= ~TIM_UIF;  // Clear flag
    // Minimal work, post to queue
}
```
