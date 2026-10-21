\ DS18B20 temperature sensor example.
\ Dependency: onewire.fth.
\ Wiring:
\   DS18B20.GND  -> GND
\   DS18B20.VDD  -> 3V3   (do NOT use parasite power)
\   DS18B20.DQ   -> GPIO  + 4.7 kOhm pull-up to 3V3
\
\ Usage: load this file, then run ow-start to initialize the bus on GPIO4.
\   scan-1w
\   read-temp
\   temp-loop

\ Change this if your sensor lives on another pin.
4 constant: OW_PIN

: scan-1w ( -- )
    "1-Wire devices on the bus:" type cr
    ['] .rom 1w-each-rom cr ;

: read-temp ( -- )
    ds18b20-read .millic cr ;

: temp-loop ( -- )
    begin read-temp 1000 ms again ;

\ One-line bring-up: open the bus and store it in 1w-bus.
: ow-start ( -- ) OW_PIN 1w-open 1w-bus ! ;
/EOF
