\ ADC measurement example (ESP32-C3).
\ Dependency: adc.fth.
\ Wiring:
\   Analog source (potentiometer wiper, sensor out, ...) -> GPIO0..GPIO4
\   Keep the input within the range selected by the attenuation.
\
\ Usage: load this file, then run adc-start to configure GPIO4.
\   adc-start
\   read-volts
\   volts-loop

\ ESP32-C3: ADC1 channel n == GPIO n. GPIO2 -> ADC_CH2.
ADC_CH4     constant: AIN
ADC_ATTEN_12DB constant: AIN_ATTEN   \ ~0..3.3 V full scale

: read-raw  ( -- ) "raw: " type adc@ . cr ;
: read-volts ( -- ) adc-mv@ .volts cr ;

: volts-loop ( -- )
    begin read-volts 1000 ms again ;

\ One-line bring-up: configure the channel + calibration.
: adc-start ( -- ) AIN AIN_ATTEN adc-setup ;
/EOF
