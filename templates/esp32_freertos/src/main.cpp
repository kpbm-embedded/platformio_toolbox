// @NAME@ (esp32_freertos template): producer/consumer with a queue, a mutex and an event group.
#include <Arduino.h>

struct Sample { uint32_t tick; uint16_t value; };

static QueueHandle_t sample_queue;
static SemaphoreHandle_t serial_mutex;
static EventGroupHandle_t events;
static constexpr EventBits_t LOGGER_READY = BIT0;

static void log_line(const char *text, uint32_t a, uint32_t b) {
    if (xSemaphoreTake(serial_mutex, pdMS_TO_TICKS(50)) == pdTRUE) {
        Serial.printf("%s %lu %lu\n", text, (unsigned long)a, (unsigned long)b);
        xSemaphoreGive(serial_mutex);
    }
}

extern "C" void sensor_task(void *) {
    xEventGroupWaitBits(events, LOGGER_READY, pdFALSE, pdTRUE, portMAX_DELAY);
    uint16_t value = 0;
    for (;;) {
        Sample sample{xTaskGetTickCount(), value++};
        if (xQueueSend(sample_queue, &sample, pdMS_TO_TICKS(10)) != pdTRUE) log_line("queue full", sample.tick, 0);
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

extern "C" void logger_task(void *) {
    xEventGroupSetBits(events, LOGGER_READY);
    Sample sample;
    for (;;) {
        if (xQueueReceive(sample_queue, &sample, portMAX_DELAY) == pdTRUE) log_line("sample", sample.tick, sample.value);
    }
}

#if CONFIG_FREERTOS_UNICORE
#define SENSOR_CORE 0
#define LOGGER_CORE 0
#else
#define SENSOR_CORE 0
#define LOGGER_CORE 1
#endif

void setup() {
    Serial.begin(115200);
    sample_queue = xQueueCreate(8, sizeof(Sample));
    serial_mutex = xSemaphoreCreateMutex();
    events = xEventGroupCreate();
    xTaskCreatePinnedToCore(sensor_task, "sensor", 3072, nullptr, 2, nullptr, SENSOR_CORE);
    xTaskCreatePinnedToCore(logger_task, "logger", 4096, nullptr, 1, nullptr, LOGGER_CORE);
}

void loop() { vTaskDelay(pdMS_TO_TICKS(1000)); }   // the Arduino loop task has nothing to do
