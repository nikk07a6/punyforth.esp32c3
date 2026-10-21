#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/timers.h"
#include "esp_vfs.h"
#include "esp_vfs_fat.h"
#include "esp_timer.h"
#include "driver/gpio.h"
#include "led_strip.h"
#include "forth_io.h"
#define ESP_INTR_FLAG_DEFAULT 0

static QueueHandle_t event_queue;

static const char *TAG = "punyforth";
static wl_handle_t s_wl_handle = WL_INVALID_HANDLE;
const esp_vfs_fat_mount_config_t mount_config = {
	.max_files = 4,
	.format_if_mount_failed = true,
	.allocation_unit_size = CONFIG_WL_SECTOR_SIZE,
	.use_one_fat = false,
};

int forth_mount_fat_spiflash(char* base_path) {
	esp_err_t err = esp_vfs_fat_spiflash_mount_rw_wl(base_path, "storage", &mount_config, &s_wl_handle);
	if (err != ESP_OK) ESP_LOGE(TAG, "Failed to mount FATFS (%s)", esp_err_to_name(err));
	return err;
}

void forth_delay_ms(int ms) {
	if (ms <= 0) { taskYIELD(); return; }
	TickType_t ticks = ms / portTICK_PERIOD_MS;
	if (ticks == 0) ticks = 1;
	vTaskDelay(ticks);
}

void forth_putchar(char c) { putchar(c); fflush(stdout); }
void forth_type(char* text) { printf("%s", text); fflush(stdout); }

int forth_getchar() {
	int c;
	while ((c = getchar()) <= 0) forth_delay_ms(10);
  return c;
}

int forth_getchar_nowait() {
	int c = getchar();
	if (c <= 0) forth_delay_ms(10);
	return c;
}
// -----------------------------------------------
int forth_time_ms() { return xTaskGetTickCount() * portTICK_PERIOD_MS; }
int forth_time_us() { return esp_timer_get_time() & 0x7ffffff; }

void forth_abort() { esp_restart(); }

void init_event_queue() {
	event_queue = xQueueCreate(12, sizeof(struct forth_event));
	gpio_install_isr_service(ESP_INTR_FLAG_DEFAULT);
}

void forth_add_event(struct forth_event *event) {
	xQueueSendToBack(event_queue, event, 1);
}

void forth_add_event_isr(struct forth_event *event) {
	xQueueSendToBackFromISR(event_queue, event, NULL);
}

int forth_wait_event(int timeout_ms, void* event) {
	return (xQueueReceive(event_queue, event, timeout_ms / portTICK_PERIOD_MS) == pdTRUE) ? 1 : 0;
}
// -----------------------------------------------
static void IRAM_ATTR gpio_isr_handler(void* arg) {
	int gpio_num = (int) arg;
	struct forth_event event = {
		.event_type    = EVT_GPIO,
		.event_time_ms = xTaskGetTickCountFromISR() * portTICK_PERIOD_MS,
		.event_time_us = forth_time_us(),
		.event_payload = gpio_num | (gpio_get_level(gpio_num) ? 0x100 : 0),
	};
	forth_add_event_isr(&event);
}

void forth_gpio_set_interrupt(int num, int intr_type) {
	gpio_set_intr_type(num, intr_type);
	gpio_isr_handler_add(num, gpio_isr_handler, (void*) num);
}

int forth_gpio_mode(int num, int dir) {
	gpio_mode_t d;
	switch (dir) {
		case 0: d = GPIO_MODE_DISABLE; break;
		case 1: d = GPIO_MODE_INPUT; break;
		case 2: d = GPIO_MODE_OUTPUT; break;
		case 3: d = GPIO_MODE_OUTPUT_OD; break;
		case 4: d = GPIO_MODE_INPUT_OUTPUT_OD; break;
		case 5: d = GPIO_MODE_INPUT_OUTPUT; break;
		default: return -1;
	}
	return gpio_set_direction(num, d);
}

int forth_gpio_pull_mode(int num, int mode) {
	gpio_pull_mode_t m;
	switch (mode) {
		case 0: m = GPIO_PULLUP_ONLY; break;
		case 1: m = GPIO_PULLDOWN_ONLY; break;
		case 2: m = GPIO_PULLUP_PULLDOWN; break ;
		case 3: m = GPIO_FLOATING; break;
		default: return -1;
	}
	return gpio_set_pull_mode(num, m);
}
// -----------------------------------------------
typedef struct {
	gpio_num_t num;
	TimerHandle_t timer;
	uint32_t ms;
	uint8_t longpress;
} gpio_btn_t;

static void IRAM_ATTR gpio_btn_isr_handler(void* arg) {
	gpio_btn_t *gpio_btn = (gpio_btn_t *) arg;
  uint32_t ms = xTaskGetTickCountFromISR() * portTICK_PERIOD_MS;
	if (gpio_get_level(gpio_btn->num)) {
		xTimerStop(gpio_btn->timer, 0);
		if (!gpio_btn->longpress && gpio_btn->ms && (gpio_btn->ms + 50 < ms)) {
	    struct forth_event event = {
		    .event_type    = EVT_BTN,
		    .event_time_ms = ms,
		    .event_time_us = forth_time_us(),
		    .event_payload = gpio_btn->num | 0x100,
	    };
	    forth_add_event_isr(&event);
		}
	  gpio_btn->ms = 0;
	}
	else {
		gpio_btn->ms = ms;
		gpio_btn->longpress = 0;
		xTimerReset(gpio_btn->timer, 0);
	}
}

static void btnTimerExpired(TimerHandle_t pxTimer) {
  gpio_btn_t* gpio_btn = (gpio_btn_t *) pvTimerGetTimerID(pxTimer);
  gpio_btn->longpress = 1;
  struct forth_event event = {
		.event_type = EVT_BTN,
		.event_time_ms = xTaskGetTickCountFromISR() * portTICK_PERIOD_MS,
		.event_time_us = forth_time_us(),
		.event_payload = gpio_btn->num  | 0x200,
	};
	forth_add_event_isr(&event);
}

int forth_btn_init(int pin) {
	gpio_btn_t* gpio_btn = malloc(sizeof(gpio_btn_t));
	gpio_btn->num = pin;
	gpio_set_direction(pin, GPIO_MODE_INPUT);
	gpio_set_pull_mode(pin, GPIO_PULLUP_ONLY);
	gpio_set_intr_type(pin, GPIO_INTR_ANYEDGE);
	gpio_btn->timer = xTimerCreate(
	  "btn_timer",
	  pdMS_TO_TICKS(800),
	  0,
	  (void *) gpio_btn,
	  btnTimerExpired);
	if (gpio_btn->timer == NULL) return 0;
	gpio_isr_handler_add(pin, gpio_btn_isr_handler, (void*) gpio_btn);
	return 1;
}
// -----------------------------------------------
static const uint8_t rstate_table[] = {
// AB  AB  AB  AB
// 00  01  10  11
    0, 16,  4,  0,    // 0
    8,  0,  4,  0,    // 1
    8, 12,  4,  0,    // 2
    8, 12,  0,  3,    // 3: delta = 1
   20, 16,  0,  0,    // 4
   20, 16, 24,  0,    // 5
   20,  0, 24,  1,    // 6: delta = -1
};
static uint8_t rstate, rAB;

void check_rstate() {
  rstate = rstate_table[rstate + rAB];
  if (rstate & 3) {
    struct forth_event event = {
      .event_type = EVT_ROTARY,
      .event_time_ms = xTaskGetTickCountFromISR() * portTICK_PERIOD_MS,
      .event_time_us = forth_time_us(),
      .event_payload = (int) rstate - 2,
    };
    forth_add_event_isr(&event);
    rstate = 0;
  }
}

void IRAM_ATTR gpio_pinA_isr_handler(void* arg) {
	int gpio_num = (int) arg;
  rAB = (rAB & 0xfd) | (gpio_get_level(gpio_num) ? 2 : 0);
  check_rstate();
}
void IRAM_ATTR gpio_pinB_isr_handler(void* arg) {
	int gpio_num = (int) arg;
  rAB = (rAB & 0xfe) | (gpio_get_level(gpio_num) ? 1 : 0);
  check_rstate();
}
void forth_rotary_init(int pinA, int pinB) {
	rstate = 0;
	rAB = 3;
	gpio_set_direction(pinA, GPIO_MODE_INPUT);
	gpio_set_pull_mode(pinA, GPIO_PULLUP_ONLY);
	gpio_set_intr_type(pinA, GPIO_INTR_ANYEDGE);
	gpio_isr_handler_add(pinA, gpio_pinA_isr_handler, (void*) pinA);
	gpio_set_direction(pinB, GPIO_MODE_INPUT);
	gpio_set_pull_mode(pinB, GPIO_PULLUP_ONLY);
	gpio_set_intr_type(pinB, GPIO_INTR_ANYEDGE);
	gpio_isr_handler_add(pinB, gpio_pinB_isr_handler, (void*) pinB);
}
// -----------------------------------------------
led_strip_handle_t forth_led_strip_init(int gpio_num, int led_numb) {
	led_strip_config_t strip_config = {
		.strip_gpio_num = gpio_num,
		.max_leds = led_numb,
	};
	led_strip_rmt_config_t rmt_config = {
        .resolution_hz = 10 * 1000 * 1000, // 10MHz
		.flags.with_dma = false,
	};
	led_strip_handle_t led_strip = malloc(sizeof(led_strip_handle_t));
    ESP_ERROR_CHECK(led_strip_new_rmt_device(&strip_config, &rmt_config, &led_strip));
	return led_strip;
}

void forth_led_strip_set_pixel(led_strip_handle_t led_strip, int i , int rgb) {
	ESP_ERROR_CHECK(led_strip_set_pixel(led_strip, i, rgb >> 16 & 0xff, rgb >> 8 & 0xff, rgb & 0xff));
	ESP_ERROR_CHECK(led_strip_refresh(led_strip));
}

void forth_led_strip_clear(led_strip_handle_t led_strip) {
	ESP_ERROR_CHECK(led_strip_clear(led_strip));
}

void forth_led_strip_del(led_strip_handle_t led_strip) {
	ESP_ERROR_CHECK(led_strip_del(led_strip));
}
