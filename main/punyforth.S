#include "data.S"
#include "macros.S"
#include "primitives.S"
#include "api.S"
#include "words.S"

.global forth_start

.section .irom0.text
.align WORD_ALIGN

/*
    s8  : xt -        
    s9  : pc - forth instruction pointer
    s10 : dp - dstack pointer
    s11 : rp - rstack pointer
*/

forth_start:
    la   t0, input_buffer
    sw   t0, input_index, t1
    
    la   s10, stack
    la   s11, rstack_top

    sw   s10, stack_top, t1
    la   s9, start_interpreter
    NEXT

start_interpreter:
    .word  xt_btick, starting_message, xt_type
    
    .word  xt_btick, mount_path, xt_mount_fat_spiflash, xt_invert, xt_branch0  // mount file system
    LBL outer_interpreter
    .word  xt_btick, dict_bin, xt_fopen_rb, xt_dup, xt_branch0   // open dict.bin
    LBL    1f
    .word  xt_dup, xt_heap_start, xt_heap_end, xt_over, xt_minus // ( file addr size ) 
    .word  xt_rot, xt_fread, xt_swap, xt_fclose                  // read dict.bin
    .word  xt_btick, var_boot_xt, xt_fetch, xt_execute           // exexute boot
1:  .word  xt_drop  
outer_interpreter:
    .word  xt_word                           // ( a len )
    .word  xt_dup2
    .word  xt_find, xt_dup, xt_branch0       // dictionary lookup returns ( link | 0 )
    LBL not_found_in_dictionary
    .word  xt_link2xt
    .word  xt_nip, xt_nip                          
    .word  xt_execute
    .word  xt_branch
    LBL outer_interpreter 
not_found_in_dictionary:                     // word was not found in the dictionary try to convert it to number
    .word  xt_drop                           // 0
    .word  xt_dup2                           // save ( len wordadr ) for printing if error occurs during conversion
    .word  xt_tonumber
    .word  xt_branch0
    LBL invalid_number
    .word  xt_nip, xt_nip                    // drop saved word 
    .word  xt_branch 
    LBL outer_interpreter
invalid_number:
    .word  xt_eundefi, xt_fetch, xt_execute
    .word  xt_branch
    LBL outer_interpreter
