
DEFPRIMITIVE REGULAR,dup,3,"dup",link=0 // ( a -- a a )
    READTOS1 t0
    DPUSH    t0
    NEXT

DEFPRIMITIVE REGULAR,qdup,4,"?dup" // ( a -- a a | 0 )
    READTOS1 t0
    beqz     t0, 1f
    DPUSH    t0
1:  NEXT

DEFPRIMITIVE REGULAR,dup2,4,"2dup" // ( a b -- a b a b )
    READTOS2 t0
    READTOS1 t1
    DPUSH    t0
    DPUSH    t1
    NEXT

DEFPRIMITIVE REGULAR,dup3,4,"3dup" // ( a b c -- a b c a b c )
    READTOS3 t0
    READTOS2 t1
    READTOS1 t2
    DPUSH    t0
    DPUSH    t1
    DPUSH    t2
    NEXT

DEFPRIMITIVE REGULAR,drop,4,"drop" // ( a -- )
    addi     s10, s10, CELLS
    NEXT

DEFPRIMITIVE REGULAR,drop2,5,"2drop"
    addi     s10, s10, 2*CELLS
    NEXT

DEFPRIMITIVE REGULAR,drop3,5,"3drop"
    addi     s10, s10, 3*CELLS
    NEXT

DEFPRIMITIVE REGULAR,drop4,5,"4drop"
    addi     s10, s10, 4*CELLS
    NEXT

DEFPRIMITIVE REGULAR,nip,3,"nip" // ( a b -- b )
    DPOP     t0
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,swap,4,"swap" // ( a b -- b a )
    READTOS2 t0
    READTOS1 t1
    WRTETOS2 t1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,swap2,5,"2swap" // ( a b c d -- c d a b )
    READTOS4 t0
    READTOS3 t1
    READTOS2 t2
    READTOS1 t3
    WRTETOS4 t2
    WRTETOS3 t3
    WRTETOS2 t0
    WRTETOS1 t1
    NEXT

DEFPRIMITIVE REGULAR,over,4,"over" // ( a b -- a b a )
    READTOS2 t0
    DPUSH    t0
    NEXT

DEFPRIMITIVE REGULAR,over2,5,"2over" // ( a b c d -- a b c d a b)
    READTOS4 t0
    READTOS3 t1
    DPUSH    t0
    DPUSH    t1
    NEXT

DEFPRIMITIVE REGULAR,rot,3,"rot" // ( a b c -- b c a )
    READTOS3 t0
    READTOS2 t1
    READTOS1 t2
    WRTETOS3 t1
    WRTETOS2 t2
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,mrot,4,"-rot" // ( a b c -- c a b )
    READTOS3 t0
    READTOS2 t1
    READTOS1 t2
    WRTETOS3 t2
    WRTETOS2 t0
    WRTETOS1 t1
    NEXT

DEFPRIMITIVE REGULAR,plus,1,"+"  // ( a b -- a+b )
    DPOP     t1
    READTOS1 t0
    add      t0, t0, t1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,minus,1,"-"  // ( a b -- a-b )
    DPOP     t1
    READTOS1 t0
    sub      t0, t0, t1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,multiply,1,"*"  // ( a b -- a*b )
    DPOP     t1
    READTOS1 t0
    mul      t0, t0, t1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,divmod,4,"/mod" // ( n d -- m q )
    DPOP     t1           // denom
    DPOP     t0           // numer
    rem      t2, t0, t1
    div      t0, t0, t1
    DPUSH    t2           // remainder
    DPUSH    t0           // quotient
    NEXT

DEFPRIMITIVE REGULAR,or,2,"or"  // ( a b -- a|b )
    DPOP     t1
    READTOS1 t0
    or       t0, t0, t1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,and,3,"and" // ( a b -- a&b )
    DPOP     t1
    READTOS1 t0
    and      t0, t0, t1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,xor,3,"xor" // ( a b -- a^b )
    DPOP     t1
    READTOS1 t0
    xor      t0, t0, t1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,invert,6,"invert" // ( a -- ~a )
    READTOS1 t0
    xori     t0, t0, -1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,lshift,6,"lshift" // ( a n -- b )
    DPOP     t1
    READTOS1 t0
    sll      t0, t0, t1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,rshift,6,"rshift" // ( a n -- b )
    DPOP     t1
    READTOS1 t0
    sra      t0, t0, t1        /////  srl ???
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,fetch,1,"@" // ( addr -- word )
    READTOS1 t0
    lw       t0,0(t0)
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,fetchbyte,2,"c@" // ( addr -- char )
    READTOS1 t0
    lbu      t0, 0(t0)
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,fetchsbyte,2,"b@"
    READTOS1 t0
    lb       t0, 0(t0)
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,fetchshort,2,"h@"
    READTOS1 t0
    lh       t0, 0(t0)
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,store,1,"!" // ( word addr -- )
    DPOP     t1
    DPOP     t0
    sw       t0, 0(t1)
    NEXT

DEFPRIMITIVE REGULAR,storebyte,2,"c!" // (char addr -- )
    DPOP     t1
    DPOP     t0
    sb       t0, 0(t1)
    NEXT

DEFPRIMITIVE REGULAR,storeshort,2,"h!" // (halfword addr -- )
    DPOP     t1
    DPOP     t0
    sh       t0, 0(t1)
    NEXT

DEFPRIMITIVE REGULAR,btick,3,"[']"    // compile only
    lw       t0, 0(s9)
    addi     s9, s9, CELLS
    DPUSH    t0
    NEXT

DEFPRIMITIVE REGULAR,eq,1,"="
    DPOP     t1
    READTOS1 t0
    li       t2, TRUE
    beq      t0, t1, 1f              // t0 = t1 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,eq0,2,"0="
    READTOS1 t0
    li       t2, TRUE
    beqz     t0, 1f                  // t0 = 0 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,eq1,2,"1="
    READTOS1 t0
    li       t1, 1
    li       t2, TRUE
    beq      t0, t1, 1f              // t0 = 1 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,lt,1,"<"
    DPOP     t1
    READTOS1 t0
    li       t2, TRUE
    blt      t0, t1, 1f              // t0 < t1 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,gt,1,">"
    DPOP     t1
    READTOS1 t0
    li       t2, TRUE
    blt      t1, t0, 1f              // t0 > t1 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,lte,2,"<="
    DPOP     t1
    READTOS1 t0
    li       t2, TRUE
    bge      t1, t0, 1f              // t0 <= t1 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,gte,2,">="
    DPOP     t1
    READTOS1 t0
    li       t2, TRUE
    bge      t0, t1, 1f              // t0 >= t1 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,noteq,2,"<>"
    DPOP     t1
    READTOS1 t0
    li       t2, TRUE
    bne      t0, t1, 1f              // t0 <> t1 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,noteq0,3,"0<>"
    READTOS1 t0
    li       t2, TRUE
    bnez     t0, 1f                  // t0 <> 0 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,lt0,2,"0<"
    READTOS1 t0
    li       t2, TRUE
    bltz     t0, 1f                  // t0 < 0 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,gt0,2,"0>"
    READTOS1 t0
    li       t2, TRUE
    bgtz     t0, 1f                  // t0 > 0 ?
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,inc,2,"1+"
    READTOS1 t0
    addi     t0, t0, 1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,dec,2,"1-"
    READTOS1 t0
    addi     t0, t0, -1
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,branch,6,"branch"
    lw       t0, 0(s9)              // read relative address as the next instruction
    add      s9, s9, t0             // advance forth PC
    NEXT

DEFPRIMITIVE REGULAR,branch0,7,"branch0"
    DPOP     t0
    beqz     t0, code_branch
    addi     s9, s9, CELLS
    NEXT

DEFPRIMITIVE REGULAR,rpush,2,">r"
    DPOP     t0
    RPUSH    t0
    NEXT

DEFPRIMITIVE REGULAR,rpop,2,"r>"
    RPOP     t0
    DPUSH    t0
    NEXT

DEFPRIMITIVE REGULAR,i,1,"i"
    lw       t0,  0(s11)
    DPUSH    t0
    NEXT

DEFPRIMITIVE REGULAR,j,1,"j"
    lw       t0, 2*CELLS(s11)
    DPUSH    t0
    NEXT

DEFPRIMITIVE REGULAR,is_space,11,"whitespace?" // ( char -- bool )
    READTOS1 t0
    li       t2, TRUE
    li       t1, 32
    beq      t0, t1, 1f
    li       t1, 10
    beq      t0, t1, 1f
    li       t1, 13
    beq      t0, t1, 1f
    li       t1, 9
    beq      t0, t1, 1f
    li       t2, FALSE
1:  WRTETOS1 t2
    NEXT

DEFPRIMITIVE REGULAR,execute,7,"execute"
    DPOP     s8                         // xt
    lw       t0, 0(s8)                  // fetch codeword the same way as the inner interpreter does
    jr       t0

// this exit primitive is only used by the compiler, this is used for detecting word endings works some as regular exit
DEFPRIMITIVE REGULAR,end_word,6,"<exit>"
    RPOP     s9                         // pop forth PC from the return stack
    NEXT

DEFPRIMITIVE REGULAR,exit,4,"exit"
    RPOP     s9                          // pop forth PC from the return stack
    NEXT

DEFPRIMITIVE REGULAR,spat,3,"sp@"
    mv       t0, s10
    DPUSH    t0
    NEXT

DEFPRIMITIVE REGULAR,spstore,3,"sp!"
    DPOP     t0
    mv       s10, t0
    NEXT

DEFPRIMITIVE REGULAR,rpat,3,"rp@"
    DPUSH    s11
    NEXT

DEFPRIMITIVE REGULAR,rpstore,3,"rp!"
    DPOP     s11
    NEXT

DEFPRIMITIVE REGULAR,rfetch,2,"r@"
    lw       t0, 0(s11)
    DPUSH    t0
    NEXT

DEFPRIMITIVE REGULAR,cells,5,"cells"
    READTOS1 t0
    slli     t0, t0, 2
    WRTETOS1 t0
    NEXT

DEFPRIMITIVE REGULAR,sspat,3,"SP@"
    DPUSH    sp
    NEXT

// ---------------------------------------------
DEFPRIMITIVE REGULAR,i2h,3,"i>h"
    READTOS1 t0
    andi     t0, t0, 0x0f
    ori      t0, t0, 0x30
    li       t1, 0x3a
    blt      t0, t1, 1f
    addi     t0, t0, 7
1:  WRTETOS1 t0
    NEXT

#define LAST_PRIMITIVE name_i2h

// Different types of code words

ENTERCOL:                       // codeword for word (colon) definitions
    RPUSH    s9                 // pc -> rstack
    addi     s9, s8, CELLS      // pc = xt + 4
    NEXT

ENTERDOES:
    RPUSH    s9                 // pc -> rstack
    lw       s9, CELLS(s8)      // pc = code address
    addi     s8, s8, 2*CELLS    // xt = xt + 8
    DPUSH    s8                 // xt -> dstack
    NEXT

ENTERCONST:
    lw       t0, CELLS(s8)
    DPUSH    t0                 // [xt+4] -> dstack
    NEXT

ENTERVAR:
    addi     s8, s8, CELLS
    DPUSH    s8                 // xt+4 -> dstack
    NEXT
