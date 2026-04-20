# Embedded Dev — Peripheral Drivers Reference

## Driver Architecture Pattern

A production embedded driver has four layers:

```
Layer 1: Platform HAL (STM32 HAL / Zephyr API / ESP-IDF)
Layer 2: Protocol layer (SPI/I2C/UART transaction management)
Layer 3: Device driver (register map, command encoding, state machine)
Layer 4: Application interface (init/read/write/configure public API)
```

Each layer hides the layer below. The application never knows whether the sensor
uses SPI or I2C — that is the device driver's concern.

---

## SPI Drivers

### Transaction State Machine

```c
typedef enum {
    SPI_IDLE,
    SPI_TX_IN_PROGRESS,
    SPI_RX_IN_PROGRESS,
    SPI_ERROR
} spi_state_t;

typedef struct {
    SPI_HandleTypeDef *hspi;
    GPIO_TypeDef      *cs_port;
    uint16_t           cs_pin;
    SemaphoreHandle_t  done_sem;  // posted by DMA complete callback
    spi_state_t        state;
    uint8_t            tx_buf[SPI_MAX_FRAME];
    uint8_t            rx_buf[SPI_MAX_FRAME];
} spi_device_t;

int spi_transfer(spi_device_t *dev, size_t len, uint32_t timeout_ms) {
    if (dev->state != SPI_IDLE) return ERR_SPI_BUSY;
    dev->state = SPI_TX_IN_PROGRESS;
    HAL_GPIO_WritePin(dev->cs_port, dev->cs_pin, GPIO_PIN_RESET);
    HAL_SPI_TransmitReceive_DMA(dev->hspi, dev->tx_buf, dev->rx_buf, len);
    if (xSemaphoreTake(dev->done_sem, pdMS_TO_TICKS(timeout_ms)) != pdTRUE) {
        dev->state = SPI_ERROR;
        HAL_GPIO_WritePin(dev->cs_port, dev->cs_pin, GPIO_PIN_SET);
        return ERR_SPI_TIMEOUT;
    }
    HAL_GPIO_WritePin(dev->cs_port, dev->cs_pin, GPIO_PIN_SET);
    dev->state = SPI_IDLE;
    return OK;
}
```

### Common SPI Sensors

| Sensor | Family | Max SPI Clock | Notes |
|---|---|---|---|
| LIS3DH | ST MEMS | 10 MHz | CPOL=1 CPHA=1 (SPI Mode 3) |
| BMI088 | Bosch IMU | 10 MHz | CPOL=1 CPHA=1 |
| W25Q128 | Flash | 80 MHz | CPOL=0 CPHA=0 (Mode 0) |
| MAX31865 | RTD ADC | 5 MHz | CPOL=1 CPHA=1 |
| MCP2515 | CAN Controller | 10 MHz | CPOL=0 CPHA=0 |

---

## I2C Drivers

### Timeout-Aware I2C Transfer

```c
// Always use timeout — HAL_MAX_DELAY can hang forever on bus stuck LOW
#define I2C_TIMEOUT_MS 10

int i2c_reg_read(I2C_HandleTypeDef *hi2c, uint8_t addr,
                 uint8_t reg, uint8_t *buf, uint16_t len) {
    HAL_StatusTypeDef st;
    st = HAL_I2C_Mem_Read(hi2c, (uint16_t)(addr << 1), reg,
                           I2C_MEMADD_SIZE_8BIT, buf, len,
                           I2C_TIMEOUT_MS);
    if (st == HAL_TIMEOUT) {
        // Bus may be stuck — attempt recovery
        i2c_bus_recovery(hi2c);
        return ERR_I2C_TIMEOUT;
    }
    if (st != HAL_OK) return ERR_I2C_FAIL;
    return OK;
}

// I2C bus recovery: toggle SCL 9 times to release stuck SDA
void i2c_bus_recovery(I2C_HandleTypeDef *hi2c) {
    HAL_I2C_DeInit(hi2c);
    // Toggle SCL 9 times
    for (int i = 0; i < 9; i++) {
        HAL_GPIO_WritePin(I2C1_SCL_PORT, I2C1_SCL_PIN, GPIO_PIN_SET);
        HAL_Delay(1);
        HAL_GPIO_WritePin(I2C1_SCL_PORT, I2C1_SCL_PIN, GPIO_PIN_RESET);
        HAL_Delay(1);
    }
    HAL_I2C_Init(hi2c);
}
```

### I2C Multi-Device Arbitration

When multiple I2C devices share a bus, transactions must not interleave.
Use a mutex to serialize access:

```c
// Global I2C1 bus mutex — all devices on I2C1 share this
static SemaphoreHandle_t i2c1_bus_mutex;

int i2c1_transaction(uint8_t addr, uint8_t *tx, uint16_t tx_len,
                     uint8_t *rx, uint16_t rx_len) {
    if (xSemaphoreTake(i2c1_bus_mutex, pdMS_TO_TICKS(50)) != pdTRUE) {
        return ERR_I2C_BUS_BUSY;
    }
    int ret = i2c_reg_write_read(addr, tx, tx_len, rx, rx_len);
    xSemaphoreGive(i2c1_bus_mutex);
    return ret;
}
```

---

## UART Drivers

### Ring Buffer + DMA + IDLE Line Detection

This pattern handles variable-length frames without polling or per-byte interrupts:

```c
#define UART_DMA_BUF  256
#define UART_RING_BUF 512

static uint8_t dma_buf[UART_DMA_BUF];
static uint8_t ring_buf[UART_RING_BUF];
static uint16_t ring_head = 0;
static uint16_t ring_tail = 0;
static uint16_t dma_prev_pos = 0;

// Call from UART IDLE IRQ handler
void uart_idle_callback(UART_HandleTypeDef *huart) {
    uint16_t dma_pos = UART_DMA_BUF - huart->hdmarx->Instance->NDTR;
    uint16_t bytes = (dma_pos >= dma_prev_pos) ?
                     (dma_pos - dma_prev_pos) :
                     (UART_DMA_BUF - dma_prev_pos + dma_pos);
    // Copy from DMA circular to ring buffer
    for (uint16_t i = 0; i < bytes; i++) {
        ring_buf[ring_tail] = dma_buf[(dma_prev_pos + i) % UART_DMA_BUF];
        ring_tail = (ring_tail + 1) % UART_RING_BUF;
    }
    dma_prev_pos = dma_pos;
    // Signal reader task
    BaseType_t yield = pdFALSE;
    xSemaphoreGiveFromISR(uart_data_sem, &yield);
    portYIELD_FROM_ISR(yield);
}
```

---

## CAN / CAN-FD

### CAN Frame Dispatch Table

```c
typedef void (*can_handler_fn)(const CAN_RxHeaderTypeDef *, const uint8_t *);

typedef struct {
    uint32_t       id;
    can_handler_fn handler;
} can_dispatch_entry_t;

static const can_dispatch_entry_t can_dispatch[] = {
    {0x100, handle_motor_setpoint},
    {0x101, handle_brake_command},
    {0x200, handle_sensor_data},
    {0x000, NULL}  // sentinel
};

void can_rx_irq(CAN_HandleTypeDef *hcan) {
    CAN_RxHeaderTypeDef header;
    uint8_t data[8];
    HAL_CAN_GetRxMessage(hcan, CAN_RX_FIFO0, &header, data);
    for (int i = 0; can_dispatch[i].handler; i++) {
        if (can_dispatch[i].id == header.StdId) {
            can_dispatch[i].handler(&header, data);
            return;
        }
    }
    LOG_WARN("Unhandled CAN ID: 0x%03X", header.StdId);
}
```

---

## ADC — Continuous DMA Scan

```c
// 8-channel ADC scan via DMA, 1kHz aggregate sample rate
#define ADC_CHANNELS 8
static uint16_t adc_dma_buf[ADC_CHANNELS * 2];  // double buffer

void adc_init(void) {
    // Configure ADC for scan mode + DMA + continuous conversion
    hadc1.Init.ContinuousConvMode = ENABLE;
    hadc1.Init.DMAContinuousRequests = ENABLE;
    HAL_ADC_Start_DMA(&hadc1, (uint32_t*)adc_dma_buf,
                      ADC_CHANNELS * 2);
}

void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef *hadc) {
    // Process second half of double buffer
    process_adc_samples(&adc_dma_buf[ADC_CHANNELS], ADC_CHANNELS);
}

void HAL_ADC_ConvHalfCpltCallback(ADC_HandleTypeDef *hadc) {
    // Process first half while DMA fills second half
    process_adc_samples(&adc_dma_buf[0], ADC_CHANNELS);
}
```

---

## Driver Testing Strategy

**Unit test approach** (host-side, not on-target):
- Abstract HAL calls behind a thin interface
- Provide mock HAL for PC-side unit tests
- Test driver state machine, error handling, and edge cases on host

**Integration test approach** (on-target):
- Use UART output for pass/fail reporting
- Test each driver with known reference hardware (calibrated sensor, loopback)
- Automate with a test runner that checks GPIO signals or UART output

**Scope**: driver self-tests must cover:
- Normal read/write cycle
- Timeout recovery
- Bus error recovery
- Repeated access (idempotency)
