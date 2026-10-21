\ ICMP ping helper.
\ Dependency: network.fth.
\ Usage: load this file, then pass a host name or address to ping.

: dd>str ( dst n -- dst+ ) 10 /mod rot swap d>str swap d>str ;
: hh:mm:ss ( dst ts -- dst+ )
    tuck 3600 / 24 % dd>str 0x3a c>str
    over 60 / 60 % dd>str 0x3a c>str
    swap 60 % dd>str ;

Event buffer: event
: .ping ( event -- bool )
    dup .payload @ ?dup if \ end ?
      \ The final event reports the transmission summary.
      dup . " packets transmitted, " type
      over .us @ dup . " received, " type
      over swap - 100 * swap / . "% packet lost, time " type
      .ms ? "ms" type cr 1
    else
      "icmp-seq=" type dup .us ? " time" type
      .ms @ dup 0< if "out" type drop else $= emit . then
      cr 0
    then ;

: ping ( host -- ) override
    dup get-host-by-name ?dup if >r 1 1 10 r> ping
      event
      begin
        dup next-event
        dup .type @ EVT_PING = if dup .ping else 0 then
      until
      2drop
    else type " - host not known" type cr
    then ;
/EOF
