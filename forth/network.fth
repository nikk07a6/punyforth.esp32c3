0 constant: WIFI_MODE_NULL
1 constant: WIFI_MODE_STA
2 constant: WIFI_MODE_AP
3 constant: WIFI_MODE_APSTA

0 constant: WIFI_AUTH_OPEN
1 constant: WIFI_AUTH_WEP
2 constant: WIFI_AUTH_WPA_PSK
3 constant: WIFI_AUTH_WPA2_PSK
4 constant: WIFI_AUTH_WPA_WPA2_PSK

0 constant: WIFI_STA_IF
1 constant: WIFI_AP_IF

exception: EWIFI

: check-status ( status -- | throws:EWIFI )
    0<> if EWIFI throw then ;

\ Connect to an existing Wi-Fi access point with the given ssid and password
\ For example:
\   "ap-pass" "ap-ssid" wifi-connect
: wifi-connect ( password ssid  -- | throws:EWIFI )
    WIFI_MODE_STA wifi-set-mode check-status
    500 ms
    wifi-set-sta-config check-status
    wifi-start check-status
    wifi-sta-connect check-status ;

\ Creates an access point mode with the given properties
\ For example:
\   4 3 0 WIFI_AUTH_WPA2_PSK "1234567890" "my-ssid" wifi-softap
: wifi-softap ( max-connections channels hidden authmode password ssid -- | throws:EWIFI )
    WIFI_MODE_AP wifi-set-mode check-status
    500 ms
    wifi-set-ap-config check-status
    wifi-start check-status ;

: .ipv4 ( ipv4 -- ) 3 0 do dup .byte $. emit 8 rshift loop .byte ;

1 constant: UDP
2 constant: TCP
exception: ELWIP
11 constant: EAGAIN

: lwip-error ( errno -- ) print: "LWIP error: " . cr ELWIP throw ;
: check ( rc -- | throw:LWIP ) 0< if get-errno lwip-error then ;

: socket-new ( type -- socket | throw:LWIP ) override socket-new dup check ;
: socket-bind ( port address socket -- | throw:LWIP ) override socket-bind check ;
: socket-listen ( socket -- | throw:LWIP ) override socket-listen check ;
: socket-connect ( port address socket -- | throw:LWIP ) override socket-connect check ;
: socket-nonblock ( socket -- | throw:LWIP ) override socket-nonblock check ;
: socket-accept ( socket -- new-socket | throw:LWIP ) override
    begin dup socket-accept dup 0< while
      get-errno dup EAGAIN <> if lwip-error then
      2drop pause
    repeat
    nip ;
0 init-variable: peer-ip-address
: socket-peer-ip ( socket -- ipv4 | throw:LWIP )
    peer-ip-address dup >r socket-peer-ip-raw check
    r> @ ;
: socket-recv ( socket len buffer -- n | throw:LWIP ) override
    begin 3dup socket-recv dup 0< while
      get-errno dup EAGAIN <> if lwip-error then
      2drop pause
    repeat
    >r 3drop r> ;
: socket-send ( socket buffer len -- n | throw:LWIP ) override
    begin 3dup socket-send dup 0< while
      get-errno dup EAGAIN <> if lwip-error then
      2drop pause
    repeat
    >r 3drop r> ;
: socket-write ( socket str -- n | throw:LWIP ) dup strlen socket-send ;
: wifi-sta-ip ( -- ipv4 ) WIFI_STA_IF wifi-ip ;
: wifi-ap-ip ( -- ipv4 ) WIFI_AP_IF wifi-ip ;

: tcp-server ( port host -- socket | throw:LWIP)
    TCP socket-new dup socket-nonblock
    ['] socket-bind keep
    dup socket-listen ;

: wifi-sta-start ( -- | throw:LWIP )
    wifi-init check 1000 ms
    wifi-start check 500 ms
    wifi-sta-connect check 1000 ms ;
/EOF
