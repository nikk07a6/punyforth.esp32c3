#include "esp_log.h"
#include "esp_adc/adc_oneshot.h"
#include "esp_adc/adc_cali.h"
#include "esp_adc/adc_cali_scheme.h"
#include "forth_adc.h"

static const char *TAG = "forth_adc";

static adc_unit_t to_unit(int unit) {
	return (unit == 2) ? ADC_UNIT_2 : ADC_UNIT_1;
}

void *forth_adc_init(int unit) {
	adc_oneshot_unit_handle_t handle = NULL;
	adc_oneshot_unit_init_cfg_t cfg = {
		.unit_id = to_unit(unit),
	};
	esp_err_t err = adc_oneshot_new_unit(&cfg, &handle);
	if (err != ESP_OK) {
		ESP_LOGE(TAG, "adc_oneshot_new_unit: %s", esp_err_to_name(err));
		return NULL;
	}
	return handle;
}

int forth_adc_config(void *unit, int channel, int atten) {
	if (!unit) return -1;
	adc_oneshot_chan_cfg_t cfg = {
		.bitwidth = ADC_BITWIDTH_DEFAULT,
		.atten = (adc_atten_t)atten,
	};
	return adc_oneshot_config_channel((adc_oneshot_unit_handle_t)unit, (adc_channel_t)channel, &cfg);
}

int forth_adc_read(void *unit, int channel) {
	if (!unit) return -1;
	int raw = 0;
	esp_err_t err = adc_oneshot_read((adc_oneshot_unit_handle_t)unit, (adc_channel_t)channel, &raw);
	if (err != ESP_OK) {
		ESP_LOGE(TAG, "adc_oneshot_read: %s", esp_err_to_name(err));
		return -1;
	}
	return raw;
}

int forth_adc_del(void *unit) {
	if (!unit) return -1;
	return adc_oneshot_del_unit((adc_oneshot_unit_handle_t)unit);
}

void *forth_adc_cali_init(int unit, int channel, int atten) {
	adc_cali_handle_t handle = NULL;
	esp_err_t err;
#if ADC_CALI_SCHEME_CURVE_FITTING_SUPPORTED
	adc_cali_curve_fitting_config_t cfg = {
		.unit_id = to_unit(unit),
		.chan = (adc_channel_t)channel,
		.atten = (adc_atten_t)atten,
		.bitwidth = ADC_BITWIDTH_DEFAULT,
	};
	err = adc_cali_create_scheme_curve_fitting(&cfg, &handle);
#elif ADC_CALI_SCHEME_LINE_FITTING_SUPPORTED
	adc_cali_line_fitting_config_t cfg = {
		.unit_id = to_unit(unit),
		.atten = (adc_atten_t)atten,
		.bitwidth = ADC_BITWIDTH_DEFAULT,
	};
	err = adc_cali_create_scheme_line_fitting(&cfg, &handle);
#else
	(void)channel;
	(void)atten;
	err = ESP_ERR_NOT_SUPPORTED;
#endif
	if (err != ESP_OK) {
		ESP_LOGE(TAG, "adc_cali_create_scheme: %s", esp_err_to_name(err));
		return NULL;
	}
	return handle;
}

int forth_adc_raw_to_mv(void *cali, int raw) {
	if (!cali) return -1;
	int mv = 0;
	esp_err_t err = adc_cali_raw_to_voltage((adc_cali_handle_t)cali, raw, &mv);
	if (err != ESP_OK) {
		ESP_LOGE(TAG, "adc_cali_raw_to_voltage: %s", esp_err_to_name(err));
		return -1;
	}
	return mv;
}

int forth_adc_cali_del(void *cali) {
	if (!cali) return -1;
#if ADC_CALI_SCHEME_CURVE_FITTING_SUPPORTED
	return adc_cali_delete_scheme_curve_fitting((adc_cali_handle_t)cali);
#elif ADC_CALI_SCHEME_LINE_FITTING_SUPPORTED
	return adc_cali_delete_scheme_line_fitting((adc_cali_handle_t)cali);
#else
	return -1;
#endif
}
