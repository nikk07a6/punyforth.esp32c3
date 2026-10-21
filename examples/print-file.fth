\ Print a named file to the terminal.
\ Dependencies: none.
\ Usage example: print-file: /f/core.fth
: print-file:
    word+0 dup fopen-rb ?dup if
      begin dup here 128 rot fgets ?dup while type repeat
      fclose drop
    else print: "Failed to open file: " type cr then ;
/EOF
