\ Copyright 2016 Lars Brinkhoff

\ Assembler for asm.js

vocabulary assembler

variable alignment
variable offset
variable memory
variable main-body
variable main-body-end


: 0align 0 alignment ! ;
: 0off 0 offset ! ;
: 0mem 0 memory ! ;

: 0asm 0align 0off 0mem ;

variable #cases
variable #total-cases
0 #cases !
0 #total-cases !

base @  hex

: byte, h-c, ;
: leb128-size 7 rshift dup if recurse 1+ else 1 then ;
: leb128, dup 080 < if byte, else dup 07F and 080 or byte, 7 rshift recurse then ;
: sign-leb128, dup 040 < if xor byte, else dup 07F and 080 or over xor byte, 7 rshift recurse then ;
: sleb128, dup 0 < if invert 07F else 0 then swap sign-leb128, ;

: block,       002 byte, 040 byte, ;
: loop,        003 byte, 040 byte, ;
: if,          004 byte, 040 byte, ;
: else,        005 byte, ;
: br,          00C byte, leb128, ;
: br_table,    00E byte, ;
: end_block,   00B byte, ;
: end_loop,    00B byte, ;
: return,      00F byte, ;

: call,        010 byte, leb128, ;
: drop,        01A byte, ;

: get_local,   020 byte, leb128, ;
: set_local,   021 byte, leb128, ;
: i32.load,    028 byte, alignment @ leb128, offset @ leb128, ;
: i32.load8_u, 02D byte, alignment @ leb128, offset @ leb128, ;
: i32.store,   036 byte, alignment @ leb128, offset @ leb128, ;
: i32.store8,  03A byte, alignment @ leb128, offset @ leb128, ;

: i32.const,   041 byte, sleb128, ;
: i32.eq,      046 byte, ;
: i32.ne,      047 byte, ;
: i32.lt_s,    048 byte, ;
: i32.gt_s,    04A byte, ;
: i32.ge_s,    04E byte, ;
: i32.add,     06A byte, ;
: i32.sub,     06B byte, ;
: i32.mul,     06C byte, ;
: i32.and,     071 byte, ;
: i32.or,      072 byte, ;
: i32.xor,     073 byte, ;

: nextcase, #total-cases @ #cases @ - br, end_block, 1 #cases +! ;

: code parse-name
  target-image header, #cases @ , host-image
  ;
: end-code nextcase, target-image ;

: start-code ;

: start-switch ;
: end-switch ;

\ : emit-insns insns insn-pointer @ swap do i c@ emit loop ;
: emit-post 00B emit 00F emit 00B emit ;

\ : insn-length insn-pointer @ insns - ;
: post-length 3 ;
: local_count 9 ;
: local-entry 009 emit 07F emit ;

base !
\ Compilation to a target image.

\ Define a target image, and words to access its contents.

\ The image can be divided into sections, each with their own address
\ range.  ORG sets the dictionary pointer, and also creates a new section.

variable first-section
variable last-section
variable sec-offset
variable sec-from
variable pre-code-sec
variable post-code-sec
variable code-sec
variable data-sec
variable data-start

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
: sec-from> cell+ cell+ ;
: sec-offset> cell+ cell+ cell+ ;
: sec-pointer0> cell+ cell+ cell+ cell+ ;
: sec-pointer1> cell+ cell+ cell+ cell+ cell+ ;

: sec-verbatim here here last-section @ dup if ! else 2drop then S_VERBATIM , here last-section ! 0 , , 0 , here 0 , here -1 , swap here swap ! ;
: end-sec-verbatim here swap ! align ;

: sec-size here here last-section @ dup if ! else 2drop then S_SIZE , here last-section ! 0 , , 0 , here 0 , here -1 , swap here swap ! ;
: end-sec-size here swap ! align ;

: .sec dup . dup @ . dup sec-next> @ . dup sec-from> @ . dup sec-offset> @ . dup sec-pointer0> @ . sec-pointer1> @ . cr ;

: next-sec sec-next> @ ;
: .secs first-section @ begin dup while dup .sec next-sec repeat drop ;

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
    host-image here swap
    dup sec-pointer1> @ sec-offset> @
    swap sec-pointer0> @ sec-offset> @ -
    \  base @ decimal over . base ! ." (size)" cr
    leb128,
    here swap do i c@ emit loop ;

: write-sec-verbatim dup sec-pointer1> @ swap sec-pointer0> @ 2dup > if do i c@ emit loop else 2drop then ;

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
 sec-verbatim
 end-sec-verbatim
end-wasm-section
2 wasm-section
  sec-verbatim
  5 leb128,
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
  0 leb128,
  decimal
  1024 leb128,
  hex
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
0A wasm-section
   sec-verbatim
   1 leb128,
   end-sec-verbatim
   sec-size
   sec-verbatim
   end-sec-verbatim
   sec-verbatim
   1 leb128,
   010 leb128,
   07F leb128,
   end-sec-verbatim
   sec-verbatim
   end-sec-verbatim
   align here pre-code-sec !
   sec-verbatim
   end-sec-verbatim
   sec-verbatim
   end-sec-verbatim
   align here code-sec !
   sec-verbatim
   end-sec-verbatim
   sec-verbatim
   end-sec-verbatim
   align here post-code-sec !
   sec-verbatim
   end-sec-verbatim
   sec-verbatim
   end-sec-verbatim
   end-sec-size
   sec-verbatim
   end-sec-verbatim
end-wasm-section
hex
0B wasm-section
   sec-verbatim
   1 leb128,
   0 leb128,
   decimal
   1024 i32.const, end_block,
   end-sec-verbatim
   sec-size
   align here data-sec !
   sec-verbatim
   end-sec-verbatim
   end-sec-size
   sec-verbatim
   end-sec-verbatim
end-wasm-section


: foreign_putchar, 2 call, ;
: foreign_bye, 3 call, ;
: foreign_open_file, 1 call, ;
: foreign_read_file, 0 call, ;

0 constant W
1 constant P
2 constant S
3 constant R
4 constant x
5 constant y
6 constant z
7 constant addr
8 constant c

hex

: push,
    S get_local,
    -4 i32.const,
    i32.add,
    S set_local, ;

: rpush,
    R get_local,
    -4 i32.const,
    i32.add,
    R set_local, ;

: to_stack,
    S get_local, ;

: to_rstack,
    R get_local, ;

: set,
    i32.store, ;

: top,
    S get_local, i32.load, ;

: rtop,
    R get_local, i32.load, ;

: pop,
    S get_local,
    4 i32.const,
    i32.add,
    S set_local, ;

: rpop,
    R get_local,
    4 i32.const,
    i32.add,
    R set_local, ;

hex
: prelude
    block,
    loop,
    W get_local,
    18 i32.const,
    i32.add,
    i32.load,
    br_table,
    #cases @ leb128,
    #cases @ 0 do i 1 + leb128, loop
    #cases @ 1 + leb128,
    end_block,
    end_block,
    ;
: write-pre-code
    host-image
    align
    here pre-code-sec @ sec-pointer0> !
    block,
    block,
    loop,
    block,
    block,
    loop,
    block,
    block,
    #cases @ 0 2dup <> if do block, loop else 2drop then
    prelude
    here pre-code-sec @ sec-pointer1> !
    align ;

: write-post-code
    host-image
    align
    here post-code-sec @ sec-pointer0> !
    P get_local,
    i32.load,
    W set_local,
    P get_local,
    4 i32.const,
    i32.add,
    P set_local,
    1 br,
    end_loop,
    end_block,
    end_block,
    0 br,
    end_block,
    0 br,
    end_block,
    0 br,
    end_loop,
    0 br,
    end_block,
    0 br,
    end_block,
    here post-code-sec @ sec-pointer1> !
    align ;
