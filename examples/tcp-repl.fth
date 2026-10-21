\ TCP REPL for one client at a time; requires tasks.fth, network.fth,
\ ringbuf.fth, and mailbox.fth.
1983 constant: PORT

0 init-variable: HOST
0 init-variable: client
128 buffer: line
1 buffer: rx-byte
128 buffer: saved-tib
0 init-variable: line-length
0 init-variable: input-token-start
0 init-variable: saved-input-size
0 init-variable: saved-input-offset
0 init-variable: saved-repl-status
0 init-variable: tx-socket
0 init-variable: tx-address
0 init-variable: tx-remaining
0 init-variable: tx-count
0 init-variable: repl-deadline

exception: ENOWIFI
exception: ELINE
exception: EREPLWRITE
exception: EDEFINITION

\ The server task hands accepted sockets to the worker through this mailbox.
1 mailbox: connections
0 task: repl-server-task
0 task: repl-worker-task

\ Send a NUL-terminated string, retrying until all bytes are written.
: repl-write ( socket str -- n )
    dup strlen tx-remaining !
    dup tx-address !
    swap tx-socket ! drop
    0 tx-count !
    begin tx-remaining @ while
        tx-socket @ tx-address @ tx-remaining @ socket-send
        dup 0= if drop EREPLWRITE throw then
        dup tx-count +!
        dup tx-address @ + tx-address !
        tx-remaining @ swap - tx-remaining !
    repeat
    tx-count @ ;

\ Route output from the client worker to TCP; other tasks keep their normal output.
: type-composite ( str -- )
    current @ repl-worker-task = client @ and if
        client @ swap repl-write drop
    else
        _type
    then ;

\ Temporary NUL-terminated buffer used to send a single emitted character.
2 buffer: emit-buf 0 emit-buf 1+ c!

: emit-composite ( char -- )
    current @ repl-worker-task = client @ and if
        emit-buf c!
        client @ emit-buf repl-write drop
    else
        _emit
    then ;

\ Save the UART interpreter's input so TCP evaluation can temporarily reuse tib.
: save-input-state ( -- )
    #tib @ saved-input-size !
    >in @ tib - saved-input-offset !
    128 0 do tib i + c@ saved-tib i + c! loop ;

\ Restore tib and its cursor after evaluating a TCP command.
: restore-input-state ( -- )
    128 0 do saved-tib i + c@ tib i + c! loop
    saved-input-size @ #tib !
    tib saved-input-offset @ + >in ! ;

\ Copy the received line into tib and reset >in to its first character.
: fill-input-buffer ( -- )
    0 #tib !
    tib >in !
    line-length @ 0 do line i + c@ chr>in loop
    13 chr>in 10 chr>in
    tib >in ! ;

\ Ignore leading whitespace before reading the next token.
: skip-input-whitespace ( -- )
    begin
        >in @ tib #tib @ + <
    while
        >in @ c@ whitespace? 0= if exit then
        >in @ 1+ >in !
    repeat ;

\ Read one token without refilling the input buffer from the UART.
: next-input-token ( -- addr len )
    >in @ input-token-start !
    begin
        >in @ tib #tib @ + <
    while
        >in @ c@ whitespace? if
            input-token-start @
            >in @ input-token-start @ -
            >in @ 1+ >in !
            exit
        then
        >in @ 1+ >in !
    repeat
    input-token-start @
    >in @ input-token-start @ - ;

: token-is ( addr len str -- bool )
    dup strlen compare ;

: begin-tcp-definition ( -- )
    skip-input-whitespace
    >in @ tib #tib @ + < 0= if EDEFINITION throw then
    createheader entercol ,
    1 state ! ;

: finish-tcp-definition ( -- )
    ['] <exit> ,
    0 state !
    lastword reveal ;

: resume-tcp-compilation ( -- )
    1 state ! ;

: compile-tcp-token ( addr len -- )
    2dup ";" token-is if
        2drop finish-tcp-definition
        exit
    then
    2dup "[" token-is if
        2drop 0 state !
        exit
    then
    2dup find dup if
        nip nip
        dup immediate? if
            link>xt execute
        else
            link>xt ,
        then
    else
        drop
        2dup >number if
            nip nip postpone: literal
        else
            eundefc @ execute
        then
    then ;

: interpret-tcp-token ( addr len -- )
    2dup ":" token-is if
        2drop begin-tcp-definition
        exit
    then
    2dup "]" token-is if
        2drop resume-tcp-compilation
        exit
    then
    2dup find dup if
        link>xt nip nip execute
    else
        drop
        2dup >number if
            nip nip
        else
            eundefi @ execute
        then
    then ;

: process-tcp-token ( addr len -- )
    state @ if
        compile-tcp-token
    else
        interpret-tcp-token
    then ;

\ Evaluate tokens without reading past this TCP line.
: interpret-input-buffer ( -- )
    begin
        skip-input-whitespace
        >in @ tib #tib @ + <
    while
        next-input-token
        process-tcp-token
    repeat ;

\ Evaluate one TCP line without disturbing the UART REPL's input or status.
: eval ( str -- )
    drop
    save-input-state
    REPL .status @ saved-repl-status !
    STOPPED REPL .status !
    fill-input-buffer
    ['] interpret-input-buffer catch
    saved-repl-status @ REPL .status !
    restore-input-state
    ?dup if
        print: "TCP REPL error: " ex-type cr
    then
    prompt @ execute ;

\ Read one byte from the current client; zero indicates a closed connection.
: read-client-byte ( -- byte | 0 )
    client @ 1 rx-byte socket-recv
    dup 0= if
        drop 0
    else
        drop rx-byte c@
    then ;

\ NUL-terminate the line for string comparisons and evaluation.
: finish-line ( -- true )
    line-length @ line + 0 swap c!
    TRUE ;

\ Collect bytes until LF or disconnect; ignore CR so CRLF is one terminator.
: read-line ( -- bool )
    0 line-length !
    begin
        read-client-byte
        dup 0= if
            drop
            line-length @ if finish-line else FALSE then
            exit
        then
        dup 10 = over 13 = or if
            dup 13 = if
                drop
            else
                drop finish-line exit
            then
        else
            line-length @ 125 >= if
                drop ELINE throw
            then
            line-length @ line + c!
            1 line-length +!
        then
    again ;

\ Wait briefly for the station address, then fail explicitly on timeout.
: wait-for-sta-ip ( -- ipv4 | throws:ENOWIFI )
    30000 ms@ + repl-deadline !
    begin
        wifi-sta-ip dup if exit then
        drop
        ms@ repl-deadline @ <
    while
        100 ms
    repeat
    ENOWIFI throw ;

\ Print the address and port clients can use to connect.
: print-listening ( -- )
    print: "PunyREPL listening on " HOST @ .ipv4
    print: ":" PORT . cr ;

\ Accept clients continuously and hand each socket to the worker task.
: server ( task -- )
    activate
    PORT 0 tcp-server
    print-listening
    begin
        dup socket-accept
        dup socket-peer-ip
        print: "PunyREPL client connected from " .ipv4 cr
        dup socket-nonblock
        connections mailbox-send
    again
    deactivate ;

\ Serve commands from the current client until it disconnects.
: command-loop ( -- )
    client @ "PunyREPL ready.\r\n" repl-write drop
    prompt @ execute
    begin
        read-line
    while
        line-length @ if
            line eval
        else
            prompt @ execute
        then
    repeat ;

\ Own a client socket for one command session and close it on every exit path.
: handle-client ( socket -- )
    client !
    ['] command-loop catch
    client @ socket-close
    0 client !
    ?dup if
        print: "TCP REPL client error: " ex-type cr
    then ;

\ Process queued clients serially so the shared client/output state stays valid.
: worker ( task -- )
    activate
    begin
        connections mailbox-receive
        ['] handle-client catch
        client @ ?dup if socket-close then
        0 client !
        ?dup if
            print: "TCP REPL worker error: " ex-type cr
        then
        print-listening
    again
    deactivate ;

\ Start the server and install TCP-aware output hooks for the worker task.
: repl-start ( -- | throws:ENOWIFI )
    wait-for-sta-ip HOST !
    println: "Starting PunyREPL.."
    multi
    ['] type-composite xtype !
    ['] emit-composite xemit !
    repl-server-task server
    repl-worker-task worker ;
/EOF
