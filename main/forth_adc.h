#ifndef __FORTH_ADC_H__
#define __FORTH_ADC_H__

/* Thin Forth-side wrappers around esp_adc oneshot + calibration.
 * Handles (unit / calibration) are exposed as opaque pointers cast to int. */

void *forth_adc_init(int unit);                            /* unit 1/2 -> handle or NULL */
int   forth_adc_config(void *unit, int channel, int atten);/* 0 on success               */
int   forth_adc_read(void *unit, int channel);             /* raw 0..4095, <0 on error   */
int   forth_adc_del(void *unit);                           /* 0 on success               */

void *forth_adc_cali_init(int unit, int channel, int atten); /* handle or NULL           */
int   forth_adc_raw_to_mv(void *cali, int raw);              /* millivolts, <0 on error  */
int   forth_adc_cali_del(void *cali);                        /* 0 on success             */

#endif
