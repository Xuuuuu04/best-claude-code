# Embedded Dev — OTA Architecture Deep Dive

## Core Principles

1. **Integrity before activation**: never activate an image that has not passed
   integrity verification (SHA-256 or EdDSA signature check)
2. **Watchdog-supervised first boot**: every OTA image gets exactly one boot attempt
   under watchdog supervision before being confirmed or rolled back
3. **Rollback path must be tested**: if rollback has never been exercised in staging,
   it cannot be trusted in production

---

## MCUboot Integration (Dual-Bank)

MCUboot is the industry-standard open-source bootloader for embedded OTA.
It supports STM32, nRF52, ESP32, and others.

### Flash Partition Layout (STM32F4 example)

```
0x0800_0000 | 64KB  | MCUboot bootloader
0x0801_0000 | 464KB | SLOT-0 (active / primary)
0x0809_4000 | 464KB | SLOT-1 (staging / upgrade)
0x0811_8000 | 16KB  | Scratch area (for swap mode)
```

### MCUboot Configuration (mcuboot.conf)

```
CONFIG_BOOT_SWAP_USING_MOVE=y       # Safer than scratch for small flash
CONFIG_BOOT_VALIDATE_SLOT1=y        # Always validate staging before swap
CONFIG_BOOT_SIGNATURE_TYPE_ECDSA_P256=y
CONFIG_BOOT_SIGNATURE_KEY_FILE="keys/root_ec_p256.pem"
CONFIG_MCUBOOT_LOG_LEVEL_WRN=y      # Reduce bootloader log size
```

### Image Signing (imgtool)

```bash
# Sign firmware binary with EdDSA P-256
imgtool sign \
  --key keys/root_ec_p256.pem \
  --header-size 0x200 \
  --align 4 \
  --version 1.2.3+4 \
  --slot-size 0x74000 \
  build/firmware.bin \
  build/firmware_signed.bin

# Verify signature before uploading
imgtool verify --key keys/root_ec_p256.pub build/firmware_signed.bin
```

### OTA Confirmation Pattern (application side)

```c
#include "bootutil/bootutil.h"

void app_main(void) {
    // ...
    bool ota_pending = (boot_swap_type() == BOOT_SWAP_TYPE_REVERT);
    if (ota_pending) {
        // Watchdog is running — must confirm within timeout
        start_ota_validation_timer(90);  // 90 second timeout
    }
    // Normal startup...
}

void ota_validation_complete(bool success) {
    if (success) {
        boot_set_confirmed();  // MCUboot: mark image as permanent
        LOG_INF("OTA confirmed — image is now permanent");
    } else {
        LOG_ERR("OTA validation failed — rollback will occur on next reset");
        // Do NOT call boot_set_confirmed() — watchdog will fire and rollback
    }
}
```

---

## ESP32 OTA (IDF Native)

```c
#include "esp_ota_ops.h"
#include "esp_https_ota.h"

void ota_task(void *pvParameter) {
    esp_https_ota_config_t ota_config = {
        .http_config = &http_config,  // includes server cert verification
    };

    esp_https_ota_handle_t https_ota_handle = NULL;
    esp_err_t err = esp_https_ota_begin(&ota_config, &https_ota_handle);
    if (err != ESP_OK) {
        LOG_E(TAG, "OTA begin failed: %s", esp_err_to_name(err));
        goto ota_end;
    }

    while (1) {
        err = esp_https_ota_perform(https_ota_handle);
        if (err != ESP_ERR_HTTPS_OTA_IN_PROGRESS) break;
    }

    if (esp_https_ota_get_image_len_read(https_ota_handle) == 
        esp_https_ota_get_image_size(https_ota_handle)) {
        err = esp_https_ota_finish(https_ota_handle);
        if (err == ESP_OK) {
            LOG_I(TAG, "OTA successful, restarting...");
            esp_restart();
        }
    }

ota_end:
    esp_https_ota_abort(https_ota_handle);
}
```

**ESP32 OTA security requirements**:
- Server certificate MUST be embedded in firmware (not fetched at runtime)
- Use `esp_https_ota` (not `esp_ota_ops` with plain HTTP)
- Enable secure boot v2 in production devices

---

## Delta OTA (Bandwidth-Constrained)

For IoT devices on cellular networks, full firmware images are expensive.
Delta OTA transmits only the diff between old and new firmware.

### janpatch / bsdiff approach

```c
// Delta patch application (runs from RAM or flash, not requiring full staging space)
#include "janpatch.h"

int apply_delta_patch(
    const uint8_t *old_image, size_t old_size,
    const uint8_t *patch,     size_t patch_size,
    uint8_t *new_image,       size_t *new_size) {
    
    janpatch_ctx ctx = {
        .source_buf = old_image, .source_size = old_size,
        .patch_buf  = patch,     .patch_size  = patch_size,
        .target_buf = new_image, .target_size = *new_size,
    };
    
    int ret = janpatch(&ctx);
    if (ret == 0) {
        *new_size = ctx.bytes_written;
    }
    return ret;
}
```

After reconstruction, verify the full new image before activating:
```c
if (sha256_verify(new_image, new_size, expected_digest) != 0) {
    // Delta patch corrupted or wrong source version
    return ERR_OTA_INTEGRITY;
}
```

---

## Anti-Rollback Counter

Prevent downgrading to a vulnerable firmware version:

```c
// In image header (MCUboot image_header_t)
// security_counter field: monotonically increasing
// Bootloader rejects images with counter < current

// MCUboot configuration
CONFIG_MCUBOOT_HW_DOWNGRADE_PREVENTION=y
CONFIG_BOOT_BOOTSTRAP=n
```

The security counter is stored in One-Time Programmable (OTP) or Efuse memory:
once incremented, it cannot be decremented even if the device is compromised.

---

## Rollback Testing Checklist

Before production deployment:
- [ ] Upload unsigned image → bootloader rejects and stays on current
- [ ] Upload older version (anti-rollback counter lower) → rejected
- [ ] Upload valid signed image → first boot under watchdog
- [ ] Kill application before ota_confirm() → watchdog fires → rollback to previous
- [ ] Successful update + ota_confirm() → permanent, old image purged
- [ ] Power loss during update write → graceful recovery, no corruption
