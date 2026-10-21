\ Network Time Protocol implementation, originally based on the work of Craig A. Lindley
\ Usage example:
\    123 "time.nist.gov" network-time

"time.nist.gov" constant: NTP_HOSTNAME
exception: ENTP
variable: con
48 constant: SIZE
SIZE byte-array: packet

: request ( -- buffer )
    SIZE 0 do 0 i packet c! loop
    0xe3  0 packet c! \ LI, Version, Mode
    0x06  2 packet c! \ Polling interval
    0xec  3 packet c! \ Peer clock precision
    0x31 12 packet c!
    0x4e 13 packet c!
    0x31 14 packet c!
    0x34 15 packet c!
    0 packet ;

: connect ( port host -- ) UDP socket-new dup con ! socket-connect ;
: send ( -- ) con @ request SIZE socket-send drop ;
: receive ( -- #bytes) con @ SIZE 0 packet socket-recv ;
: dispose ( -- ) con @ socket-close ;
: ask ( port host -- #bytes ) connect { send receive } catch dispose throw ;

: parse ( -- )
    40 packet c@ 24 lshift
    41 packet c@ 16 lshift or
    42 packet c@  8 lshift or
    43 packet c@           or
    2208988800 - ;

: network-time ( port host -- seconds-since-1970 | throws:ENTP )
    get-host-by-name ask SIZE = if parse else ENTP throw then ;

0 init-variable: clock
0 init-variable: last-sync
0 init-variable: offset    \ UTC+00:00. To set e.g. EDT (UTC-4) set offset = -240
: age ( -- ms ) ms@ last-sync @ - ;
: expired? ( -- bool ) age 60000 15 * > ;
: fetch ( -- ts ) 123 NTP_HOSTNAME network-time ;
: sync ( -- ) { fetch clock ! ms@ last-sync ! } catch ?dup if print: "sync error:" ex-type cr then ;
: time ( -- ts ) clock @ offset @ 60 * + age 1000 / + ;
/EOF
