\ BLE Nordic UART (wireless serial)
\ Primitives: bt-init bt-set-name bt-advertise bt-stop-advertise
\             bt-connected bt-available bt-read bt-write

: bt-start ( name -- )
    bt-init 0= if
        bt-set-name drop
        bt-advertise drop
    else
        drop
        print: "bt-init failed" cr
    then ;

: bt-emit ( c -- )
    here >r r@ c! r> 1 bt-write drop ;

: bt-type ( str -- )
    dup strlen bt-write drop ;

: bt-readchar-nowait ( -- c | -1 )
    bt-available 0= if -1 exit then
    here 1 bt-read 0= if -1 exit then
    here c@ ;

/EOF
