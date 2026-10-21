\ LED-strip blink example.
\ Dependency: tasks.fth.
\ Usage: load this file, then run start-blink.

0 task: blink-task
: blink ( task -- )
    activate
    2 1 led-strip-init
    \ Seed the pixel/color values used by the blink loop.
    0 0x10
    begin 3dup led-strip-set-pixel 0x1010 xor 2000 delay again
    deactivate ;

: start-blink
    multi
    blink-task blink ;
/EOF
