    .data
#define WORD_ALIGN 2
#define CELLS 4
#define STATE_COMPILE 1
#define STATE_INTERPRET 0
#define IMMEDIATE 128
#define HIDDEN 64
#define REGULAR 0
#define TRUE -1
#define FALSE 0
#define INPUT_BUFFER_SIZE 128
#define MAX_WORD_LEN 63

starting_message:     .asciz "\nPunyforth (ESP32-C3), version " PUNYFORTH_VERSION "\n\n"
compile_only_warning: .asciz "\nWord has no interpretation semantics\n"
undef_word_error:     .asciz "\nUndefined word: "
inbuf_overflow_error: .asciz "\nInput overflow\n"
word_overflow_error:  .asciz "\nName too long: "
mount_path:           .asciz "/f"
dict_bin:             .asciz "/f/dict.bin"
RB_MODE:              .asciz "rb"
WB_MODE:              .asciz "wb"
failed_to_open_file:  .asciz "Failed to open file: "

    .align WORD_ALIGN
stack_top:      .word  0
state_var:      .word  STATE_INTERPRET
input_index:    .word  input_buffer
input_buffer:   .space INPUT_BUFFER_SIZE,' '
    .align WORD_ALIGN
input_size:     .word  0
input_file:     .word  0
dictionary:
var_last_word:  .word FINAL_WORD
var_prompt_xt:  .word xt_space
var_pause_xt:   .word 0
var_emit_xt:    .word xt_uemit
var_type_xt:    .word xt_utype
var_eundefi_xt: .word xt_eundef
var_eundefc_xt: .word xt_eundef
var_boot_xt:    .word xt_nop
var_dp:         .word heap
heap:
    .space 64*1024   // 64Kb
end_dictionary:
rstack_space:   .space 112
rstack_top:
stack_space:    .space 112
stack:
