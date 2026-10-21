\ TCP echo server example.
\ Dependencies: tasks.fth and network.fth.
\ Usage: initialize Wi-Fi and connect as a station, load this file, then run start-echo.
\ The server listens on port 5000 and echoes received bytes to each client.

0 task: echo-task
5000 constant: PORT
128 buffer: buf128
variable: HOST
: echo-server ( task -- )
    activate
    PORT HOST @ tcp-server
    begin
      print: "Waiting for clients on host " HOST @ .ipv4 print: " on port " PORT . cr
      dup socket-accept dup socket-nonblock
      begin
        dup 128 buf128 socket-recv ?dup
      while
        over buf128 rot socket-send drop
      repeat
      socket-close
    again
    deactivate ;

: start-echo
    multi
    wifi-sta-ip HOST !
    echo-task echo-server ;
