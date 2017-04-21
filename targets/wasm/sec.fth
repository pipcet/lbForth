\ Compilation to a target image.

\ Define a target image, and words to access its contents.

\ The image can be divided into sections, each with their own address
\ range.  ORG sets the dictionary pointer, and also creates a new section.

variable first-section
variable last-section
variable sec-offset
variable sec-from
variable pre-code-sec

\ section layout:
\  <type>
\  <next>
\  <from>
\  <offset>
\  <pointer0>
\  <pointer1>

: S_VERBATIM 1 ;
: S_SIZE 2 ;

: sec-next> cell+ ;
: sec-from> 2 cells + ;
: sec-offset> 3 cells + ;
: sec-pointer0> 4 cells + ;
: sec-pointer1> 5 cells + ;

\ : ! 2dup ! ." ! " . . cr ;
: v@ dup ." @ " . source type sp@ . cr @ ;

: sec-verbatim here here last-section @ dup if ! else 2drop then S_VERBATIM , here last-section ! 0 , , 0 , here 0 , here -1 , swap here swap ! ;
: end-sec-verbatim here swap ! align ;

: sec-size here here last-section @ dup if ! else 2drop then S_SIZE , here last-section ! 0 , , 0 , here 0 , here -1 , swap here swap ! ;
: end-sec-size here swap ! ;

: .sec dup . dup @ . dup sec-next> @ . dup sec-from> @ . dup sec-offset> @ . dup sec-pointer0> @ . sec-pointer1> @ . cr ;

: next-sec sec-next> @ ;
: .secs first-section @ begin sp@ . cr dup while dup .sec next-sec repeat drop ;

: size-sec-verbatim
    dup sec-from @ swap sec-from> !
    dup sec-offset @ swap sec-offset> !
    dup sec-pointer1> @ swap sec-pointer0> @ - sec-offset +! ;

: size-sec-size
    dup sec-pointer1> @ sec-from> @ over sec-from> @ = if
      sec-from @ over sec-from> !
      dup sec-pointer1> @ sec-offset> @
      swap sec-pointer0> @ sec-offset> @ - leb128-size
      sec-offset +!
      drop
    else
    dup sec-pointer1> @ sec-from> @ over sec-pointer0> @ sec-from> @ = if
      sec-from @ over sec-from> !
      sec-offset @ over sec-offset> !
      dup sec-pointer1> @ sec-offset> @
      swap sec-pointer0> @ sec-offset> @ - leb128-size
      sec-offset +!
      drop
    else
      next-sec sec-from> @ sec-from !
      0 sec-offset !
    then then ;

: size-section dup dup @ case
  S_VERBATIM of size-sec-verbatim endof
  S_SIZE of size-sec-size endof
  endcase
  sec-from> @ first-section @ <> ;

: size-sections2  first-section @ sec-from !
    0 sec-offset !
0 first-section @ begin dup while dup swap size-section rot or swap next-sec repeat drop ;

: size-sections begin size-sections2 while repeat ;

: wasm-section ( id -- ) sec-verbatim swap leb128, end-sec-verbatim sec-size ;
: end-wasm-section end-sec-size sec-verbatim end-sec-verbatim ;

: write-sec-size
    here swap
    dup sec-pointer1> @ sec-offset> @
    swap sec-pointer0> @ sec-offset> @ -
    \ base @ decimal over . base ! ." (size)" cr
    leb128,
    here swap do i c@ emit loop ;

: write-sec-verbatim dup sec-pointer1> @ swap sec-pointer0> @ 2dup <> if do i c@ emit loop else 2drop then ;

: write-section dup @ S_VERBATIM = if
  write-sec-verbatim else
  write-sec-size then ;


: write-sections first-section @ begin dup while dup write-section next-sec repeat ;

: wasm-string, dup leb128, bounds do i c@ c, loop ;


hex
align
here first-section !
sec-verbatim
  0 c,
  char a c,
  char s c,
  char m c,
end-sec-verbatim
sec-verbatim
  1 c,
  0 c,
  0 c,
  0 c,
end-sec-verbatim
1 wasm-section
 sec-verbatim
  2 leb128,
  060 byte,
  4 leb128,
  07F byte,
  07F byte,
  07F byte,
  07F byte,
  0 byte,
  060 byte,
  4 leb128,
  07F byte,
  07F byte,
  07F byte,
  07F byte,
  1 byte,
  07F byte,
 end-sec-verbatim
end-wasm-section
2 wasm-section
  sec-verbatim
  4 leb128,
  s" sys" wasm-string,
  s" read_file" wasm-string,
  0 leb128,
  1 leb128,
  s" sys" wasm-string,
  s" open_file" wasm-string,
  0 leb128,
  1 leb128,
  s" sys" wasm-string,
  s" emit" wasm-string,
  0 leb128,
  1 leb128,
  s" sys" wasm-string,
  s" bye" wasm-string,
  0 leb128,
  1 leb128,
  s" sys" wasm-string,
  s" memory" wasm-string,
  2 leb128,
  1 leb128,
  1024 leb128,
  1024 leb128,
  end-sec-verbatim
end-wasm-section
3 wasm-section
   sec-verbatim
   1 leb128,
   0 leb128,
   end-sec-verbatim
end-wasm-section
7 wasm-section
   sec-verbatim
   1 leb128,
   s" forth" wasm-string,
   0 leb128,
   4 leb128,
   end-sec-verbatim
end-wasm-section
: code parse-name
  header, 0 , #cases @ , reveal
  sec-verbatim ;
: end-code nextcase, end-sec-verbatim ;
0A wasm-section
   sec-verbatim
   1 leb128,
   end-sec-verbatim
   sec-size
   sec-verbatim
   1 leb128,
   010 leb128,
   07F leb128,
   end-sec-verbatim
   align here pre-code-sec !
   sec-verbatim
   42 byte, 42 byte, 42 byte,
   end-sec-verbatim
include targets/wasm/nucleus.fth
   sec-verbatim
   0 br,
   return,
   end,
   end-sec-verbatim
   end-sec-size
   sec-verbatim
   end-sec-verbatim
end-wasm-section

: write-pre-code
   align
   here pre-code-sec @ sec-pointer0> !
   #cases @ 0 2dup <> if do block, loop else 2drop then
   prelude
   here pre-code-sec @ sec-pointer1> !
   align ;

write-pre-code

size-sections
hex
write-sections
