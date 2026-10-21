\ BLE Nordic UART Service (NUS) echo example.
\ Dependency: bt.fth.
\ Usage: load bt.fth, start advertising with "PunyForth" bt-start,
\ then run bt-echo and connect with a BLE NUS client.
\ - эхо каждого принятого байта;
\ - 0x0D (CR) превращается в 0x0D 0x0A (CR+LF);
\ - выход по приёму 0x04 (Ctrl-D).

variable: evt-buf 4 cells allot

: bt-echo ( -- )
    begin
        evt-buf 1000 wait-event if
            evt-buf @ 142 = if                       \ EVT_BT_RX
                begin bt-available 0> while
                    here 1 bt-read drop
                    here c@
                    dup 4 = if drop exit then        \ Ctrl-D - выход
                    dup bt-emit                      \ эхо
                    13 = if 10 bt-emit then          \ CR -> CR+LF
                repeat
            then
        then
    again ;
/EOF
