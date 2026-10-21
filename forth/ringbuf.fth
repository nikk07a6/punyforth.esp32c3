\ Fixed-capacity FIFO ring buffer. RingBuf header is followed by capacity cells.
struct
\ Index of the oldest element and next write position, respectively.
    cell field: .i
    cell field: .j
    cell field: .capacity
    cell field: .size
constant: RingBuf

: ringbuf ( capacity -- ringbuffer )
    here tuck
    \ Reserve the elements immediately after the header.
    over cells RingBuf + allot
    0 over .i !
    0 over .j !
    0 over .size !
    .capacity ! ;

: ringbuf: ( capacity ) ( -- ringbuffer )
    create: ringbuf drop ;

: ringbuf-size ( ringbuffer -- n ) .size @ ;

: ringbuf-empty? ( ringbuffer -- bool ) ringbuf-size 0= ;

: ringbuf-full? ( ringbuffer -- bool )
    { .size @ } { .capacity @ } bi = ;

\ Convert a logical ring index into the address of its element cell.
: slot ( index ringbuffer -- adr )
    RingBuf + swap cells + ;

\ .j points to the next free cell; .i points to the oldest element.
: back-slot ( ringbuffer -- adr )
    dup .j @
    swap slot ;

: front-slot ( ringbuffer -- adr )
    dup .i @
    swap slot ;

: increase-size ( ringbuffer -- ) .size 1 swap +! ;

\ Record an insertion and wrap the next-write index at capacity.
: added ( ringbuffer -- )
    dup
    dup increase-size
    { .capacity @ } { .j @ } bi
    1+ swap %
    swap .j ! ;

: decrease-size ( ringbuffer -- ) .size -1 swap +! ;

\ Record a removal and wrap the oldest-element index at capacity.
: removed ( ringbuffer -- )
    dup
    dup decrease-size
    { .capacity @ } { .i @ } bi
    1+ swap %
    swap .i ! ;

: ringbuf-enqueue ( element ringbuffer -- | EOVERFLOW )
    dup ringbuf-full? if
        EOVERFLOW throw
    then
    tuck
    back-slot !
    added ;

: ringbuf-dequeue ( ringbuffer -- element | EUNDERFLOW )
    dup ringbuf-empty? if
        EUNDERFLOW throw
    then
    dup
    front-slot @
    swap
    removed ;
/EOF
