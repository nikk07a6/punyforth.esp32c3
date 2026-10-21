#include "esp_log.h"
#include "onewire_bus.h"
#include "onewire_crc.h"
#include "onewire_device.h"
#include "forth_1wire.h"

static const char *TAG = "forth_1w";

void *forth_1w_init(int pin) {
	onewire_bus_handle_t bus = NULL;
	onewire_bus_config_t bus_cfg = {
		.bus_gpio_num = pin,
		.flags = { .en_pull_up = true },
	};
	onewire_bus_rmt_config_t rmt_cfg = { .max_rx_bytes = 16 };
	esp_err_t err = onewire_new_bus_rmt(&bus_cfg, &rmt_cfg, &bus);
	if (err != ESP_OK) {
		ESP_LOGE(TAG, "onewire_new_bus_rmt: %s", esp_err_to_name(err));
		return NULL;
	}
	return bus;
}

int forth_1w_del(void *bus) {
	if (!bus) return -1;
	return onewire_bus_del((onewire_bus_handle_t)bus);
}

int forth_1w_reset(void *bus) {
	if (!bus) return -1;
	return onewire_bus_reset((onewire_bus_handle_t)bus);
}

int forth_1w_write(void *bus, const void *buf, int n) {
	if (!bus || !buf || n <= 0) return -1;
	return onewire_bus_write_bytes((onewire_bus_handle_t)bus, (const uint8_t *)buf, (uint8_t)n);
}

int forth_1w_read(void *bus, void *buf, int n) {
	if (!bus || !buf || n <= 0) return -1;
	return onewire_bus_read_bytes((onewire_bus_handle_t)bus, (uint8_t *)buf, (uint8_t)n);
}

void *forth_1w_search_begin(void *bus) {
	if (!bus) return NULL;
	onewire_device_iter_handle_t iter = NULL;
	esp_err_t err = onewire_new_device_iter((onewire_bus_handle_t)bus, &iter);
	if (err != ESP_OK) {
		ESP_LOGE(TAG, "onewire_new_device_iter: %s", esp_err_to_name(err));
		return NULL;
	}
	return iter;
}

int forth_1w_search_next(void *iter, void *rom8) {
	if (!iter || !rom8) return -1;
	onewire_device_t dev;
	esp_err_t err = onewire_device_iter_get_next((onewire_device_iter_handle_t)iter, &dev);
	if (err == ESP_OK) {
		// onewire stores address little-endian (family code in lowest byte).
		uint64_t a = dev.address;
		uint8_t *p = (uint8_t *)rom8;
		for (int i = 0; i < 8; i++) {
			p[i] = (uint8_t)(a & 0xff);
			a >>= 8;
		}
		return 1;
	}
	if (err == ESP_ERR_NOT_FOUND) return 0;
	return -err;
}

int forth_1w_search_end(void *iter) {
	if (!iter) return -1;
	return onewire_del_device_iter((onewire_device_iter_handle_t)iter);
}

int forth_1w_crc8(const void *buf, int n) {
	if (!buf || n <= 0) return 0;
	return onewire_crc8(0, (const uint8_t *)buf, (uint8_t)n);
}
