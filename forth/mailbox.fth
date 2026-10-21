\ Cooperative-task mailbox backed by a ring buffer; load ringbuf.fth first.
: mailbox: ( size ) ( -- mailbox ) ringbuf: ;

\ Wait cooperatively while full, then enqueue the message.
: mailbox-send ( message mailbox -- )
    begin
        dup ringbuf-full?
    while
        pause
    repeat
    ringbuf-enqueue ;

\ Wait cooperatively while empty, then return the oldest message.
: mailbox-receive ( mailbox -- message )
    begin
        dup ringbuf-empty?
    while
        pause
    repeat
    ringbuf-dequeue ;
/EOF
