# Embedded Dev — Power Management and OTA Architecture

## Power Management Deep Dive

### STM32 Low-Power Modes

| Mode | Description | Entry | Exit | Current (STM32L4) |
|------|-------------|-------|------|-------------------|
| Sleep | CPU stopped, peripherals running | WFI/WFE | Any interrupt | ~1 mA |
| Low-Power Sleep | CPU stopped, low-power regulators | WFI + LPSDSR | Any interrupt | ~120 uA |
| Stop1 | 1.2V domain off, SRAM retained | EnterStopMode | EXTI/WKUP | ~8 uA |
| Stop2 | Most clocks off, LSE running | EnterStop2Mode | EXTI/WKUP | ~1.2 uA |
| Standby | Everything off, RTC optional | EnterSTANDBYMode | WKUP pin/RTC | ~0.12 uA |
| Shutdown | Lowest power, no RTC | EnterSHUTDOWNMode | WKUP pin only | ~0.03 uA |

**Stop2 mode with RTC wakeup**:
```c
void enter_stop2(uint32_t sleep_seconds) {
    // Disable all peripheral clocks
    __HAL_RCC_GPIOA_CLK_DISABLE();
    __HAL_RCC_GPIOB_CLK_DISABLE();
    // Keep only RTC and wakeup GPIO clocked
    
    // Configure RTC wakeup timer
    HAL_RTCEx_SetWakeUpTimer_IT(&hrtc, sleep_seconds, RTC_WAKEUPCLOCK_CK_SPRE_16BITS);
    
    // Enter Stop2
    HAL_PWR_EnterSTOPMode(PWR_LOWPOWERREGULATOR_ON, PWR_STOPENTRY_WFI);
    
    // On wakeup: reconfigure system clock
    SystemClock_Config();
    
    // Re-enable peripheral clocks
    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();
}
```

### ESP32 Power Management

```c
#include "esp_pm.h"
#include "esp_sleep.h"

// Configure dynamic frequency scaling
esp_pm_config_t pm_config = {
    .max_freq_mhz = 240,
    .min_freq_mhz = 40,
    .light_sleep_enable = true
};
esp_pm_configure(&pm_config);

// Deep sleep with GPIO wake
esp_sleep_enable_gpio_wakeup();
esp_sleep_enable_timer_wakeup(10 * 1000000);  // 10 seconds
esp_deep_sleep_start();

// RTC memory persists across deep sleep
RTC_DATA_ATTR static uint32_t boot_count = 0;
```

### nRF52 System OFF

```c
// System OFF — lowest power mode, GPIO wake only
// All RAM lost unless explicitly retained

// Configure retention
NRF_POWER->RAM[0].POWERSET = POWER_RAM_POWER_S0POWER_On;  // Retain section 0

// Enable wake on button press
nrf_gpio_cfg_sense_input(BUTTON_PIN, NRF_GPIO_PIN_PULLUP, NRF_GPIO_PIN_SENSE_LOW);

// Enter System OFF
NRF_POWER->SYSTEMOFF = 1;
// CPU stops here — execution resumes from reset on wake
```

### Peripheral Power Gating Checklist

Before entering any sleep mode:
- [ ] All SPI/I2C transactions complete, CS high
- [ ] DMA channels stopped / disabled
- [ ] UART idle, DMA stopped
- [ ] ADC stopped, DMA stopped
- [ ] Timer PWM outputs in safe state
- [ ] Unused GPIO: analog mode (no pull, no drive)
- [ ] Peripheral clocks disabled: `__HAL_RCC_SPI1_CLK_DISABLE()`
- [ ] External sensors powered down via load switch
- [ ] Debug interface disabled (SWD pins consume power)

### Power Budget Calculation Template

```
Component          Active (mA)  Sleep (uA)  Duty Cycle  Average (uA)
------------------ ------------ ----------- ----------- ------------
MCU (Run/Stop2)    5.0          1.2         1%          50.0 + 1.2
Radio (TX/RX)      120.0        0.5         0.1%        120.0 + 0.5
Sensor (active)    2.1          0.3         10%         210.0 + 0.3
Flash (read)       10.0         1.0         0.1%        10.0 + 1.0
LED indicator      2.0          0.0         0.1%        2.0 + 0.0
------------------ ------------ ----------- ----------- ------------
TOTAL                                           392.3 uA

Battery life (2000mAh): 2000 / 0.392 = 5102 hours = 212 days
```

---

## OTA Architecture Deep Dive

### MCUboot Complete Integration

**Flash partition layout (STM32H5 with 1MB dual-bank)**:
```
0x0800_0000 | 64KB  | MCUboot bootloader
0x0801_0000 | 448KB | SLOT-0 (active / primary)
0x0808_0000 | 448KB | SLOT-1 (staging / upgrade)
0x080F_0000 | 64KB  | Scratch area (swap mode)
```

**MCUboot configuration (mcuboot.conf)**:
```
CONFIG_BOOT_SWAP_USING_MOVE=y       # Safer than scratch for small flash
CONFIG_BOOT_VALIDATE_SLOT0=y        # Validate active on every boot
CONFIG_BOOT_VALIDATE_SLOT1=y        # Always validate staging before swap
CONFIG_BOOT_SIGNATURE_TYPE_ECDSA_P256=y
CONFIG_BOOT_SIGNATURE_KEY_FILE="keys/root_ec_p256.pem"
CONFIG_MCUBOOT_HW_DOWNGRADE_PREVENTION=y
CONFIG_MCUBOOT_LOG_LEVEL_WRN=y
```

**Image signing workflow**:
```bash
# 1. Build firmware
west build -b my_board app/

# 2. Sign with imgtool
imgtool sign \
  --key keys/root_ec_p256.pem \
  --header-size 0x200 \
  --align 8 \
  --version 1.2.3+4 \
  --slot-size 0x70000 \
  build/zephyr/zephyr.bin \
  build/zephyr/zephyr_signed.bin

# 3. Verify signature
imgtool verify --key keys/root_ec_p256.pub build/zephyr/zephyr_signed.bin
```

**Application-side OTA confirmation**:
```c
#include "bootutil/bootutil.h"
#include "bootutil/image.h"

void app_main(void) {
    struct boot_rsp rsp;
    int rc = boot_go(&rsp);
    if (rc != 0) {
        LOG_ERR("Bootloader error: %d", rc);
        NVIC_SystemReset();
    }
    
    // Check if this is a first boot of new image
    bool ota_pending = (boot_swap_type() == BOOT_SWAP_TYPE_REVERT);
    if (ota_pending) {
        LOG_INF("OTA first boot — starting validation timer");
        start_ota_validation_timer(90);  // 90 second timeout
    }
    
    // Normal application startup...
}

void ota_validation_complete(bool success) {
    if (success) {
        boot_set_confirmed();  // Mark image as permanent
        LOG_INF("OTA confirmed — image permanent");
    } else {
        LOG_ERR("OTA validation failed — rollback on next reset");
        // Do NOT confirm — watchdog will trigger rollback
    }
}
```

### ESP32-C6 OTA with Rollback

```c
#include "esp_ota_ops.h"
#include "esp_https_ota.h"
#include "esp_partition.h"

static const char *TAG = "ota";

void ota_task(void *pvParameter) {
    esp_err_t ret = ESP_FAIL;
    
    // Verify running partition
    const esp_partition_t *running = esp_ota_get_running_partition();
    ESP_LOGI(TAG, "Running partition: %s", running->label);
    
    esp_https_ota_config_t ota_config = {
        .http_config = &(esp_http_client_config_t){
            .url = CONFIG_OTA_FIRMWARE_URL,
            .cert_pem = server_cert_pem_start,  // Embedded server cert
            .timeout_ms = 10000,
        },
    };
    
    esp_https_ota_handle_t https_ota_handle = NULL;
    ret = esp_https_ota_begin(&ota_config, &https_ota_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "OTA begin failed: %s", esp_err_to_name(ret));
        goto ota_end;
    }
    
    // Download and write firmware
    while (1) {
        ret = esp_https_ota_perform(https_ota_handle);
        if (ret != ESP_ERR_HTTPS_OTA_IN_PROGRESS) {
            break;
        }
        ESP_LOGI(TAG, "OTA progress: %d/%d bytes",
                 esp_https_ota_get_image_len_read(https_ota_handle),
                 esp_https_ota_get_image_size(https_ota_handle));
    }
    
    // Verify complete download
    if (esp_https_ota_get_image_len_read(https_ota_handle) == 
        esp_https_ota_get_image_size(https_ota_handle)) {
        ret = esp_https_ota_finish(https_ota_handle);
        if (ret == ESP_OK) {
            ESP_LOGI(TAG, "OTA successful, restarting...");
            esp_restart();  // Boot new image
        } else {
            ESP_LOGE(TAG, "OTA finish failed: %s", esp_err_to_name(ret));
        }
    } else {
        ESP_LOGE(TAG, "OTA incomplete download");
    }
    
ota_end:
    esp_https_ota_abort(https_ota_handle);
    vTaskDelete(NULL);
}

// First boot validation
void validate_ota_image(void) {
    const esp_partition_t *running = esp_ota_get_running_partition();
    esp_ota_img_states_t ota_state;
    esp_err_t ret = esp_ota_get_state_partition(running, &ota_state);
    
    if (ret == ESP_OK && ota_state == ESP_OTA_IMG_PENDING_VERIFY) {
        ESP_LOGI(TAG, "First boot of new image — validating...");
        
        // Run validation checks
        bool valid = run_application_self_test();
        
        if (valid) {
            esp_ota_mark_app_valid_cancel_rollback();
            ESP_LOGI(TAG, "Image validated — rollback cancelled");
        } else {
            esp_ota_mark_app_invalid_rollback_and_reboot();
            // Never returns — system reboots with rollback
        }
    }
}
```

### Delta OTA (Bandwidth-Constrained)

For cellular IoT devices, full firmware images (500KB+) are expensive. Delta OTA transmits only the binary diff.

```c
#include "janpatch.h"

// Delta patch application
int apply_delta_ota(
    const uint8_t *current_image, size_t current_size,
    const uint8_t *patch_data, size_t patch_size,
    uint8_t *new_image_buffer, size_t buffer_size) {
    
    janpatch_ctx ctx = {
        .source_buf = current_image,
        .source_size = current_size,
        .patch_buf = patch_data,
        .patch_size = patch_size,
        .target_buf = new_image_buffer,
        .target_size = buffer_size,
    };
    
    int ret = janpatch(&ctx);
    if (ret != 0) {
        LOG_ERR("Delta patch failed: %d", ret);
        return ERR_OTA_PATCH;
    }
    
    // Verify reconstructed image
    uint8_t expected_digest[32];
    get_expected_digest(expected_digest);  // From OTA metadata
    
    if (sha256_verify(new_image_buffer, ctx.bytes_written, expected_digest) != 0) {
        LOG_ERR("Delta patch integrity check failed");
        return ERR_OTA_INTEGRITY;
    }
    
    return 0;
}
```

**Typical delta sizes**:
- Minor update (bug fix): 5-15KB delta vs 500KB full
- Medium update (new features): 50-100KB delta vs 500KB full
- Major update (framework change): 150-250KB delta vs 500KB full

### Anti-Rollback Implementation

```c
// Security counter stored in OTP/efuse
// Once incremented, CANNOT be decremented even if device is compromised

// MCUboot anti-rollback
#define SECURITY_COUNTER_ADDR 0x1FFF7000  // OTP region

bool check_anti_rollback(uint32_t new_image_counter) {
    uint32_t current_counter = *(volatile uint32_t *)SECURITY_COUNTER_ADDR;
    
    if (new_image_counter < current_counter) {
        LOG_ERR("Anti-rollback: new image counter (%lu) < current (%lu)",
                new_image_counter, current_counter);
        return false;  // Reject downgrade
    }
    
    return true;
}

void increment_security_counter(uint32_t new_counter) {
    // OTP write — one-time programmable, irreversible
    HAL_FLASH_Unlock();
    HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, SECURITY_COUNTER_ADDR, new_counter);
    HAL_FLASH_Lock();
}
```

### Rollback Testing Checklist

Before ANY production deployment:
- [ ] Upload unsigned image -> bootloader rejects, stays on current
- [ ] Upload image with wrong signature -> bootloader rejects
- [ ] Upload older version (lower security counter) -> rejected by anti-rollback
- [ ] Upload valid signed image -> first boot under watchdog
- [ ] Kill application before ota_confirm() -> watchdog fires -> rollback to previous
- [ ] Successful update + ota_confirm() -> permanent, old image available for next rollback
- [ ] Power loss during update write -> graceful recovery, no corruption
- [ ] Power loss during bank swap -> bootloader recovers, attempts rollback
- [ ] Delta OTA with wrong source version -> patch fails, no corruption
- [ ] Validate all rollback paths in staging environment before production
