// Predefined words in binary (compiled) forth

DEFWORD REGULAR,cell,4,"cell",link=LAST_API
    .word xt_btick, CELLS
    .word xt_end_word

DEFWORD REGULAR,tuck,4,"tuck" // ( a b -- b a b )
    .word xt_swap, xt_over
    .word xt_end_word

DEFWORD REGULAR,us0,3,"_s0"
    .word xt_btick, stack_top, xt_fetch
    .word xt_end_word

DEFWORD REGULAR,ur0,3,"_r0"
    .word xt_btick, rstack_top
    .word xt_end_word

DEFWORD REGULAR,comma,1,","
    .word xt_here, xt_store
    .word xt_here, xt_cell, xt_plus
    .word xt_var_dp, xt_store
    .word xt_end_word

DEFWORD REGULAR,commabyte,2,"c,"
    .word xt_dp, xt_storebyte
    .word xt_dp, xt_inc
    .word xt_var_dp, xt_store
    .word xt_end_word

DEFWORD REGULAR,commashort,2,"h,"
    .word xt_dp, xt_align2, xt_tuck, xt_storeshort
    .word xt_inc, xt_inc
    .word xt_var_dp, xt_store
    .word xt_end_word

DEFWORD REGULAR,toin,3,">in"
    .word xt_btick, input_index
    .word xt_end_word

DEFWORD REGULAR,inputlen,4,"#tib"
    .word xt_btick, input_size
    .word xt_end_word

DEFWORD REGULAR,tib,3,"tib"
    .word xt_btick, input_buffer
    .word xt_end_word

DEFWORD REGULAR,state,5,"state"
    .word xt_btick, state_var
    .word xt_end_word

DEFWORD IMMEDIATE,literal,7,"literal"
    .word xt_btick, xt_btick, xt_comma
    .word xt_comma
    .word xt_end_word

DEFWORD REGULAR,compare,7,"compare" //( a1 len1 a2 len2 - bool )
    .word xt_rot, xt_swap                                                          // (a1 a2 len1 len2)
    .word xt_dup2, xt_eq, xt_branch0
    LBL compare_length_mismatch
    .word xt_drop                                                                  // both lengths are equal, leave only one of them  (a1 a2 len)
compare_next_char:
    .word xt_dup, xt_branch0
    LBL compare_equal
    .word xt_mrot                                                                  // (len a1 a2)
    .word xt_dup2                                                                  // (len a1 a2 a1 a2)
    .word xt_fetchbyte, xt_swap, xt_fetchbyte, xt_eq                               // check if next characters are equal
    .word xt_branch0
    LBL compare_not_equal
    .word xt_inc, xt_swap, xt_inc, xt_swap
    .word xt_rot
    .word xt_dec
    .word xt_branch
    LBL compare_next_char
compare_equal:
    .word xt_drop3
    .word xt_btick, TRUE
    .word xt_exit
compare_not_equal:
    .word xt_drop3
    .word xt_btick, FALSE
    .word xt_exit
compare_length_mismatch:
    .word xt_drop4
    .word xt_btick, FALSE
    .word xt_end_word

DEFWORD REGULAR,find,4,"find" // ( a len -- link | 0 )
    .word xt_lastword
find_try_next_word:                                                               // (a1 len1 link)
    .word xt_dup
    .word xt_branch0
    LBL find_not_found
    .word xt_dup, xt_is_hidden, xt_invert, xt_branch0
    LBL find_skip_hidden
    .word xt_dup, xt_swap2, xt_rot                                                 // (link a1 len1 link)
    .word xt_dup
    .word xt_link2len, xt_swap
    .word xt_link2name, xt_swap                                                    // (link a1 len1 a2 len2)
    .word xt_over2                                                                 // (link a1 len1 a2 len2 a1 len1)
    .word xt_compare, xt_invert                                                    // (link a1 len1 bool)
    .word xt_branch0
    LBL find_found
    .word xt_rot                                                                   // (a1 len1 link)
find_skip_hidden:
    .word xt_fetch
    .word xt_branch
    LBL find_try_next_word
find_found:
    .word xt_drop2
    .word xt_exit                                                    // return the dictionary link
find_not_found:
    .word xt_drop3
    .word xt_btick, 0
    .word xt_end_word

DEFWORD REGULAR,align,5,"align"
    .word xt_btick, 3, xt_plus, xt_btick, 3, xt_invert, xt_and
    .word xt_end_word

DEFWORD REGULAR,align2,6,"align2"
    .word xt_inc, xt_btick, 1, xt_invert, xt_and
    .word xt_end_word

DEFWORD REGULAR,here,4,"here"
    .word xt_dp, xt_align
    .word xt_end_word

DEFWORD REGULAR,dp,2,"dp"
    .word xt_var_dp, xt_fetch
    .word xt_end_word

DEFWORD REGULAR,var_dp,6,"var-dp"
    .word xt_btick, var_dp
    .word xt_end_word

DEFWORD REGULAR,heap_start,10,"heap-start"
    .word xt_btick, dictionary
    .word xt_end_word

DEFWORD REGULAR,heap_end,8,"heap-end"
    .word xt_btick, end_dictionary
    .word xt_end_word

DEFWORD REGULAR,align_bang,6,"align!" // (  -- )
    .word xt_here, xt_var_dp, xt_store
    .word xt_end_word

DEFWORD REGULAR,allot,5,"allot" // ( n -- )
    .word xt_here, xt_plus, xt_align, xt_var_dp, xt_store
    .word xt_end_word

DEFWORD REGULAR,createheader,12,"createheader"
    .word xt_word, xt_swap
    .word xt_btick, var_last_word, xt_fetch, xt_comma                        // store link to previous word
    .word xt_here, xt_cell, xt_minus, xt_btick, var_last_word, xt_store      // update last word
    .word xt_swap, xt_dup, xt_btick, REGULAR, xt_or, xt_commabyte        // write length + flags
create_write_next_char:
    .word xt_dup, xt_branch0
    LBL create_name_done
    .word xt_swap, xt_dup, xt_fetchbyte, xt_commabyte
    .word xt_inc                                                            // increment name address
    .word xt_swap, xt_dec                                                   // decrement length
    .word xt_branch
    LBL create_write_next_char
create_name_done:
    .word xt_drop2
    .word xt_here, xt_var_dp, xt_store                                      // align after name
    .word xt_end_word

DEFWORD REGULAR,tonumber,7,">number" // ( a len -- number TRUE | FALSE )
    .word xt_dup, xt_branch0
    LBL tonum_empty
    .word xt_over, xt_fetchbyte, xt_btick, 45, xt_eq                       // check sign
    .word xt_branch0
    LBL tonum_positive
    .word xt_dec //( len )
    .word xt_swap
    .word xt_inc //( addr )
    .word xt_swap
    .word xt_btick, -1, xt_rpush                                                   // store sign on rstack
    .word xt_branch
    LBL start_convert
tonum_positive:
    .word xt_btick, 1, xt_rpush
start_convert:
    .word xt_btick, 0, xt_swap //( addr result len )
tonum_loop:
    .word xt_dup, xt_branch0
    LBL tonum_done
    .word xt_mrot
    .word xt_btick, 10, xt_multiply
    .word xt_over, xt_fetchbyte
    .word xt_dup, xt_btick, 47, xt_gt, xt_branch0                                  // check range
    LBL tonum_invalid_digit
    .word xt_dup, xt_btick, 58, xt_lt, xt_branch0
    LBL tonum_invalid_digit
    .word xt_btick, 48, xt_minus, xt_plus
    .word xt_swap, xt_inc, xt_swap
    .word xt_rot, xt_dec // ( len )
    .word xt_branch
    LBL tonum_loop
tonum_done:
    .word xt_drop //( len )
    .word xt_rpop, xt_multiply //( * sign )
    .word xt_nip //( addr )
    .word xt_btick, TRUE
    .word xt_exit
tonum_invalid_digit:
    .word xt_rpop, xt_drop //( sign )
    .word xt_drop4
    .word xt_btick, FALSE
    .word xt_exit
tonum_empty:
    .word xt_drop2
    .word xt_btick, FALSE
    .word xt_end_word

DEFWORD REGULAR,word,4,"word" // ( -- a len )
word_trim:
    .word xt_key, xt_is_space, xt_invert, xt_branch0
    LBL word_trim
    .word xt_toin, xt_fetch, xt_dec                          // ( a )
word_next_char:
    .word xt_key, xt_is_space, xt_branch0
    LBL word_next_char
    .word xt_toin, xt_fetch, xt_over, xt_minus, xt_dec       // (a len )
    .word xt_dup, xt_btick, MAX_WORD_LEN, xt_lte, xt_branch0
    LBL word_too_long
    .word xt_exit
word_too_long:
    .word xt_btick, word_overflow_error, xt_type
    .word xt_typecounted, xt_btick, 10, xt_emit
    .word xt_abort

DEFWORD REGULAR,colon,1,":"
    .word xt_createheader
    .word xt_btick, ENTERCOL, xt_comma                                         // codeword is ENTERCOL
    .word xt_compiler
    .word xt_end_word

DEFWORD REGULAR,eundef,6,"eundef"
    .word xt_btick, undef_word_error, xt_type
    .word xt_typecounted
    .word xt_btick, 13, xt_emit
    .word xt_btick, 10, xt_emit
    .word xt_tib, xt_inputlen, xt_fetch, xt_plus, xt_toin, xt_store // skip rest of the inputbuffer
    .word xt_end_word

DEFWORD REGULAR,compiler,1,"]"
    .word xt_btick, STATE_COMPILE, xt_btick, state_var, xt_store
compile:
    .word xt_word                           // ( a len )
    .word xt_dup2, xt_btick, 1, xt_eq, xt_swap, xt_fetchbyte, xt_btick, 91, xt_eq, xt_and, xt_invert // is [ ?
    .word xt_branch0
    LBL suspend_compile
    .word xt_dup2, xt_btick, 1, xt_eq, xt_swap, xt_fetchbyte, xt_btick, 59, xt_eq, xt_and // is ; ?
    .word xt_branch0
    LBL no_end
    .word xt_drop2, xt_btick, xt_end_word, xt_comma
    .word xt_btick, STATE_INTERPRET, xt_btick, state_var, xt_store
    .word xt_lastword, xt_reveal, xt_exit
no_end:
    .word xt_dup2, xt_find, xt_dup // ( link | 0 )
    .word xt_branch0
    LBL not_found_dict
    .word xt_nip, xt_nip, xt_dup, xt_is_immediate
    .word xt_branch0
    LBL do_compile
    .word xt_link2xt, xt_execute
    .word xt_branch
    LBL compile
do_compile:
    .word xt_link2xt, xt_comma
    .word xt_branch
    LBL compile
not_found_dict:
    .word xt_drop // 0
    .word xt_dup2, xt_tonumber
    .word xt_branch0
    LBL undefword
    .word xt_nip, xt_nip
    .word xt_literal           // we are in compile mode, compile a literal number
    .word xt_branch
    LBL compile
undefword:
    .word xt_eundefc, xt_fetch, xt_execute
    .word xt_branch
    LBL compile
suspend_compile:
    .word xt_nip, xt_nip
    .word xt_btick, STATE_INTERPRET, xt_btick, state_var, xt_store
    .word xt_end_word

DEFWORD REGULAR,eundefi,7,"eundefi"
    .word xt_btick, var_eundefi_xt
    .word xt_end_word

DEFWORD REGULAR,eundefc,7,"eundefc"
    .word xt_btick, var_eundefc_xt
    .word xt_end_word

DEFWORD REGULAR,xemit,5,"xemit"
    .word xt_btick, var_emit_xt
    .word xt_end_word

DEFWORD REGULAR,emit,4,"emit"            // ( char -- )
    .word xt_xemit, xt_fetch, xt_execute
    .word xt_end_word

DEFWORD REGULAR,space,5,"space"
    .word xt_btick, ' ', xt_emit
    .word xt_end_word

DEFWORD REGULAR,cr,2,"cr"
    .word xt_btick, 13, xt_emit, xt_btick, 10, xt_emit
    .word xt_end_word

DEFWORD REGULAR,xtype,5,"xtype"
    .word xt_btick, var_type_xt
    .word xt_end_word

DEFWORD REGULAR,type,4,"type"            // ( asciiz -- )
    .word xt_xtype, xt_fetch, xt_execute
    .word xt_end_word

.ifndef xt_typecounted
DEFWORD REGULAR,typecounted,12,"type-counted" // : type-counted ( addr count -- )
type_counted_next_char:                       //     begin
    .word xt_dup, xt_branch0                  //       dup
    LBL type_counted_done                     //     while
    .word xt_dec, xt_swap, xt_dup             //       1- swap dup
    .word xt_fetchbyte, xt_emit               //       c@ emit
    .word xt_inc, xt_swap                     //       1+ swap
    .word xt_branch                           //     repeat
    LBL type_counted_next_char
type_counted_done:
    .word xt_drop2                            //     2drop ;
    .word xt_end_word
.endif

DEFWORD REGULAR,char_toin,6,"chr>in"   // (chr -- )
    .word xt_inputlen, xt_fetch, xt_btick, INPUT_BUFFER_SIZE, xt_lt, xt_branch0
    LBL inbuf_overflow
    .word xt_toin, xt_fetch, xt_storebyte                       // store one char in inputbuffer
    .word xt_toin, xt_fetch, xt_inc, xt_toin, xt_store          // increment input index
    .word xt_inputlen, xt_fetch, xt_inc, xt_inputlen, xt_store  // incrment input size
    .word xt_exit
inbuf_overflow:
    .word xt_btick, inbuf_overflow_error, xt_type
    .word xt_abort

DEFWORD REGULAR,char_fromin,7,"in>char"   // ( -- chr )
    .word xt_toin, xt_fetch, xt_fetchbyte                       // fetch next character from inputbuffer
    .word xt_toin, xt_fetch, xt_inc, xt_toin, xt_store          // increment input index
    .word xt_end_word

DEFWORD REGULAR,prompt,6,"prompt"
    .word xt_btick, var_prompt_xt
    .word xt_end_word

DEFWORD REGULAR,show_prompt,11,"show_prompt"
    .word xt_input_file, xt_fetch, xt_branch0
    LBL 1f
    .word xt_exit
1:  .word xt_prompt, xt_fetch, xt_execute
    .word xt_end_word

DEFWORD REGULAR,input_file,10,"input-file"
    .word xt_btick, input_file
    .word xt_end_word

DEFWORD REGULAR,key,3,"key"
    .word xt_tib, xt_inputlen, xt_fetch, xt_plus
    .word xt_toin, xt_fetch, xt_swap, xt_gte
    .word xt_branch0
    LBL read_one_char_from_buffer
    .word xt_btick, 0, xt_inputlen, xt_store    // reset inputlen
    .word xt_tib, xt_toin, xt_store             // reset inputbuffer
    .word xt_show_prompt
refill_buffer:
    .word xt_readchar, xt_dup, xt_char_toin
    .word xt_btick, 10, xt_eq, xt_branch0
    LBL refill_buffer
    .word xt_tib, xt_toin, xt_store
read_one_char_from_buffer:
    .word xt_char_fromin
    .word xt_end_word

DEFWORD REGULAR,compile_time,12,"compile-time"
    .word xt_state, xt_fetch, xt_btick, STATE_COMPILE, xt_eq
    .word xt_branch0
    LBL cannot_interpret_compile_only_word
    .word xt_exit
cannot_interpret_compile_only_word:
    .word xt_btick, compile_only_warning, xt_type
    .word xt_end_word

DEFWORD REGULAR,var_lastword,12,"var-lastword"
    .word xt_btick, var_last_word
    .word xt_end_word

DEFWORD REGULAR,lastword,8,"lastword"
    .word xt_var_lastword, xt_fetch
    .word xt_end_word

DEFWORD REGULAR,constant,9,"constant:"
    .word xt_createheader
    .word xt_btick, ENTERCONST, xt_comma, xt_comma
    .word xt_end_word

DEFWORD REGULAR,initvar,14,"init-variable:"
    .word xt_createheader
    .word xt_btick, ENTERVAR, xt_comma, xt_comma
    .word xt_end_word

DEFWORD REGULAR,enterdoes,9,"enterdoes"
    .word xt_btick, ENTERDOES
    .word xt_end_word

DEFWORD REGULAR,entercol,8,"entercol"
    .word xt_btick, ENTERCOL
    .word xt_end_word

DEFWORD REGULAR,link2flb,8,"link>flb" // ( a1 -- a2 )
    .word xt_cell, xt_plus
    .word xt_end_word

DEFWORD REGULAR,link2len,8,"link>len" // ( a1 -- len )
    .word xt_link2flb, xt_fetchbyte, xt_btick, 0b00111111, xt_and
    .word xt_end_word

DEFWORD REGULAR,link2flags,10,"link>flags" // ( a1 -- flags )
    .word xt_link2flb, xt_fetchbyte, xt_btick, 0b11000000, xt_and
    .word xt_end_word

DEFWORD REGULAR,link2name,9,"link>name" // ( a1 -- a2 )
    .word xt_cell, xt_plus, xt_inc
    .word xt_end_word

DEFWORD REGULAR,link2xt,7,"link>xt" // ( a1 -- a2 )
    .word xt_dup, xt_link2name, xt_swap
    .word xt_link2len, xt_plus, xt_align
    .word xt_end_word

DEFWORD REGULAR,link2body,9,"link>body" // ( a1 -- a2 )
    .word xt_link2xt, xt_cell, xt_plus
    .word xt_end_word

DEFWORD REGULAR,is_hidden,7,"hidden?" // link -- bool
    .word xt_link2flags, xt_btick, HIDDEN, xt_and, xt_btick, HIDDEN, xt_eq
    .word xt_end_word

DEFWORD REGULAR,hide,4,"hide" // ( link -- )
    .word xt_btick, HIDDEN, xt_over, xt_link2flb, xt_fetchbyte, xt_or
    .word xt_swap, xt_link2flb, xt_storebyte
    .word xt_end_word

DEFWORD REGULAR,reveal,6,"reveal" // ( link -- )
    .word xt_btick, HIDDEN, xt_invert, xt_over, xt_link2flb, xt_fetchbyte, xt_and
    .word xt_swap, xt_link2flb, xt_storebyte
    .word xt_end_word

DEFWORD REGULAR,is_immediate,10,"immediate?" // ( link -- bool)
    .word xt_link2flags, xt_btick, IMMEDIATE, xt_and, xt_btick, IMMEDIATE, xt_eq
    .word xt_end_word

DEFWORD REGULAR,readchar,8,"readchar"
    .word xt_xpause, xt_fetch, xt_branch0
    LBL readchar_blocking
readchar_again:
    .word xt_readchar_nowait, xt_dup, xt_btick, -1, xt_eq, xt_branch0
    LBL readchar_available
    .word xt_drop
    .word xt_xpause, xt_fetch, xt_execute
    .word xt_branch
    LBL readchar_again
readchar_available:
    .word xt_exit
readchar_blocking:
    .word xt_readchar_wait
    .word xt_end_word

DEFWORD REGULAR,xpause,6,"xpause"
    .word xt_btick, var_pause_xt
    .word xt_end_word

DEFWORD REGULAR,type_hexbyte,3,".hb"
    .word xt_dup, xt_btick, 4, xt_rshift, xt_i2h, xt_emit
    .word xt_i2h, xt_emit
    .word xt_end_word

DEFWORD REGULAR,type_hexaddr,3,".ha"
    .word xt_dup, xt_btick, 24, xt_rshift, xt_type_hexbyte
    .word xt_dup, xt_btick, 16, xt_rshift, xt_type_hexbyte
    .word xt_dup, xt_btick, 8, xt_rshift, xt_type_hexbyte
    .word xt_type_hexbyte
    .word xt_end_word

DEFWORD IMMEDIATE,immediate,9,"immediate"
    .word xt_btick, IMMEDIATE, xt_lastword, xt_link2flb, xt_fetchbyte, xt_or
    .word xt_lastword, xt_link2flb, xt_storebyte
    .word xt_end_word

DEFWORD REGULAR,boot_bung,5,"boot!"  // ( xt -- )
    .word xt_btick, var_boot_xt, xt_store
    .word xt_end_word

DEFWORD REGULAR,save_dict,9,"save-dict" // ( -- n )
    .word  xt_btick, dict_bin, xt_fopen_wb, xt_dup, xt_branch0
    LBL  1f
    .word xt_dup, xt_heap_start, xt_here, xt_over, xt_minus, xt_rot
    .word xt_fwrite, xt_swap, xt_fclose
1:  .word xt_end_word

DEFWORD REGULAR,word0,6,"word+0" // ( -- str )
    .word xt_word, xt_over, xt_plus, xt_btick, 0, xt_swap, xt_storebyte
    .word xt_end_word

DEFWORD REGULAR,load,5,"load:"
    .word xt_word0, xt_dup, xt_fopen_rb, xt_qdup, xt_branch0
    LBL 1f
    .word xt_input_file, xt_store, xt_drop, xt_exit
1:  .word xt_btick, failed_to_open_file, xt_type, xt_type, xt_cr
    .word xt_end_word

FINAL_WORD:
DEFWORD REGULAR,nop,3,"nop"
    .word xt_end_word
