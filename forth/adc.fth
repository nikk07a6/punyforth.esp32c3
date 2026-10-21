\ ADC (analog-to-digital) helpers for ESP32-C3.
\ Primitives (in api.S):
\   adc-init  adc-config  adc-read  adc-del
\   adc-cali-init  adc-raw>mv  adc-cali-del

exception: EADC

\ ADC units
1 constant: ADC1
2 constant: ADC2

\ Attenuation (sets the input voltage range):
\   0 dB    -> ~0..950 mV
\   2.5 dB  -> ~0..1250 mV
\   6 dB    -> ~0..1750 mV
\   12 dB   -> ~0..3300 mV
0 constant: ADC_ATTEN_0DB
1 constant: ADC_ATTEN_2_5DB
2 constant: ADC_ATTEN_6DB
3 constant: ADC_ATTEN_12DB

\ On ESP32-C3, ADC1 channels 0..4 map to GPIO0..GPIO4.
0 constant: ADC_CH0
1 constant: ADC_CH1
2 constant: ADC_CH2
3 constant: ADC_CH3
4 constant: ADC_CH4

: adc-check ( rc -- | throws:EADC ) 0< if EADC throw then ;

\ Open an ADC unit, throwing on failure.
: adc-open ( unit -- handle | throws:EADC )
    adc-init dup 0= if drop EADC throw then ;

\ Open a calibration profile for unit/channel/atten, throwing on failure.
: adc-cali-open ( unit channel atten -- cali | throws:EADC )
    adc-cali-init dup 0= if drop EADC throw then ;

\ Most code uses a single unit + calibration; stash them here.
variable: adc-unit
variable: adc-cali

\ Set up a single channel on ADC1 with the given attenuation, plus calibration.
\ After this, `adc@` reads raw counts and `adc-mv@` reads millivolts.
variable: adc-ch
: adc-setup ( channel atten -- | throws:EADC )
    2dup                                   ( channel atten channel atten )
    ADC1 -rot adc-cali-open adc-cali !     ( channel atten )  \ R: -
    over adc-ch !
    ADC1 adc-open adc-unit !
    adc-unit @ -rot adc-config adc-check ;

\ Read the raw ADC count for the configured channel.
: adc@ ( -- raw | throws:EADC )
    adc-unit @ adc-ch @ adc-read dup adc-check ;

\ Read the calibrated voltage in millivolts for the configured channel.
: adc-mv@ ( -- mv | throws:EADC )
    adc-cali @ adc@ adc-raw>mv dup adc-check ;

\ Print a non-negative integer as 3 digits with leading zeros.
: adc-pad3 ( n -- )
    dup 100 < if $0 emit then
    dup  10 < if $0 emit then
    . ;

\ Print a millivolt value as "1.234 V".
: .volts ( mv -- ) 1000 /mod . $. emit adc-pad3 space $V emit ;

/EOF
