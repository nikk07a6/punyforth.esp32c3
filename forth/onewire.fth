\ Dallas 1-Wire bus & DS18B20 helpers
\ Primitives (in api.S):
\   1w-init  1w-del  1w-reset  1w-write  1w-read  1w-crc8
\   1w-search-begin  1w-search-next  1w-search-end

exception: E1WIRE

\ Standard 1-Wire ROM commands
0xCC constant: 1W_SKIP_ROM
0x55 constant: 1W_MATCH_ROM
0xF0 constant: 1W_SEARCH_ROM
0x33 constant: 1W_READ_ROM
0xEC constant: 1W_SEARCH_ALARM

: 1w-check ( rc -- | throws:E1WIRE ) 0<> if E1WIRE throw then ;

\ Init 1-Wire on a pin and throw on failure.
: 1w-open ( pin -- bus | throws:E1WIRE )
    1w-init dup 0= if drop E1WIRE throw then ;

\ Most code only uses a single bus -- stash it here.
variable: 1w-bus

\ ------ "current bus" sugar ------
: 1w-reset!  ( -- )       1w-bus @ 1w-reset 1w-check ;
: 1w-emit    ( c -- )     here c! 1w-bus @ here 1 1w-write 1w-check ;
: 1w-type    ( buf n -- ) 1w-bus @ -rot 1w-write 1w-check ;
: 1w-read!   ( buf n -- ) 1w-bus @ -rot 1w-read  1w-check ;
: 1w-key     ( -- c )     1w-bus @ here 1 1w-read 1w-check here c@ ;

\ Iterate every ROM on the current bus.
\ xt has stack effect ( rom8 -- ); rom8 is valid only for the duration of the call.
8 buffer: 1w-rom-buf
: 1w-each-rom ( xt -- )
    1w-bus @ 1w-search-begin       ( xt iter|0 )
    dup 0= if 2drop exit then
    swap >r                        \ ( iter )  R: xt
    begin
      dup 1w-rom-buf 1w-search-next 1 = while
      1w-rom-buf r@ execute
    repeat
    1w-search-end drop r> drop ;

\ Print an 8-byte ROM address as XX:XX:XX:XX:XX:XX:XX:XX (family code first).
: .rom ( rom8 -- )
    8 0 do
      dup i + c@ .hb
      i 7 <> if $: emit then
    loop drop ;

\ Match a specific device by its 8-byte ROM address.
: 1w-match ( rom8 -- ) 1w-reset! 1W_MATCH_ROM 1w-emit 8 1w-type ;

\ ------ DS18B20 helpers ------
0x44 constant: DS18B20_CONVERT
0xBE constant: DS18B20_READ_SCRATCH

\ Combine the two raw scratchpad bytes (LSB first) into a signed 16-bit value.
: 1w-i16 ( lo hi -- n )
    8 lshift or
    dup 0x8000 and if 0x10000 - then ;

\ Convert a raw DS18B20 reading (units of 1/16 °C) into milli-degrees C.
\ raw * 1000 / 16 == raw * 125 / 2; do *625/10 to keep integer precision.
: ds18b20-raw>millic ( raw -- millic ) 625 * 10 / ;

\ Kick off a temperature conversion on every DS18B20 on the current bus.
: ds18b20-start ( -- )
    1w-reset! 1W_SKIP_ROM 1w-emit DS18B20_CONVERT 1w-emit ;

\ Worst-case 12-bit conversion time.
: ds18b20-wait ( -- ) 750 ms ;

9 buffer: ds18b20-buf

\ Read the scratchpad of the (single) device on the bus and return the
\ temperature in milli-degrees C. Throws E1WIRE on CRC mismatch.
: ds18b20-temp ( -- millic | throws:E1WIRE )
    1w-reset! 1W_SKIP_ROM 1w-emit DS18B20_READ_SCRATCH 1w-emit
    ds18b20-buf 9 1w-read!
    ds18b20-buf 9 1w-crc8 0<> if E1WIRE throw then
    ds18b20-buf c@ ds18b20-buf 1+ c@ 1w-i16
    ds18b20-raw>millic ;

\ One-shot single-device read: start conversion, wait, read.
: ds18b20-read ( -- millic | throws:E1WIRE )
    ds18b20-start ds18b20-wait ds18b20-temp ;

\ Print a non-negative integer as 3 digits with leading zeros.
: .pad3 ( n -- )
    dup 100 < if $0 emit then
    dup  10 < if $0 emit then
    . ;

\ Print a milli-degree value as "23.500 C".
: .millic ( millic -- )
    dup 0< if $- emit then abs
    1000 /mod . $. emit .pad3
    space $C emit ;

/EOF
