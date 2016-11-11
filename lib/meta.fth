\ Metacompiler.  Copyright Lars Brinkhoff 2016.

require search.fth

vocabulary compiler

vocabulary t-words
defer t,
: t-word ( a u xt -- ) -rot "create , does> @ t, ;
: fatal   cr source type cr bye ;
: ?undef   0= if ." Undefined!" fatal then ;
: t-search   ['] t-words search-wordlist ;
: defined?   t-search if drop -1 else 0 then ;
: "' ( u a -- xt ) t-search ?undef >body @ ;
: t'   parse-name "' ;
: t-compile   parse-name postpone sliteral postpone "' postpone t, ; immediate
: t-[compile]   also compiler ' previous compile, ; immediate
: t-literal   t-compile (literal) t, ;
: t-constant   create , does> @ t-literal ;

: already-defined?   >in @ >r parse-name defined? r> >in ! ;
: trailing-semicolon?   source 1- + c@ [char] ; = ;
: ignore-definition   begin trailing-semicolon? postpone \ until ;

variable leaves
: 0leaves   0 leaves ! ;
: leaves@   leaves @ ;

vocabulary meta
only forth also meta definitions
include lib/image.fth

0 value latest

' , is t,

s" " searched
s" src/" searched
include params.fth
: >link   next-offset + ;
: >code   code-offset + ;
: >body   body-offset + ;

777 value 'docol
777 value 'dovar
777 value 'docon
777 value 'dodef
777 value 'dodoes

: code,   , ;

: link, ( nt -- ) latest ,  to latest ;
: reveal ;

include target.fth

variable #code
1 #code !

: new-code  #code @ #code dup @ 1 + swap ! ;
: header, ( a u -- ) 2dup align here over >xt drop t-word header, ;
: ?code, ( -- ) new-code , ;

: host   only forth definitions host-image ;

: target   only forth also meta also t-words definitions previous target-image ;
include asm.fth
include lib/xforward.fth

only forth definitions also meta
variable 'perform
: target   only forth also meta also t-words definitions previous target-image ;

target

1024 allot

include nucleus.fth

s" docol" header, 0 , 0 , t' >r , t' exit ,
s" dovar" header, 0 , 0 , t' exit ,
s" docon" header, 0 , 0 , t' @ , t' exit ,
s" dodef" header, 0 , 0 , here >host 'perform ! 777 , t' exit ,

host also meta definitions

: exe-header
   create-rsnippets
   ." function asmmodule(stdlib, foreign, buffer) {" cr
   [char] " emit ." use asm" [char] " emit ." ;" cr
    ." var HEAPU8 = new stdlib.Uint8Array(buffer);" cr
    ." var HEAPU32 = new stdlib.Uint32Array(buffer);" cr
    ." var imul = stdlib.Math.imul;" cr
    ." var foreign_putchar = foreign.foreign_putchar;" cr
    ." var foreign_sys_open = foreign.foreign_sys_open;" cr
    ." var foreign_sys_read = foreign.foreign_sys_read;" cr
    ." var foreign_exit = foreign.foreign_exit;" cr

   ." function main(word, IP, SP, RP) {" cr
   ." word = word|0;" cr
   ." IP = IP|0;" cr
   ." SP = SP|0;" cr
   ." RP = RP|0;" cr
   ." var addr = 0;" cr
   ." var x = 0;" cr
   ." var y = 0;" cr
   ." var z = 0;" cr
   ." var c = 0;" cr
   ." var i = 0;" cr
   ." var top = 0;" cr
   ." while (1|0) {" cr
   ." //console.log([word, name(word), IP, SP, RP, HEAPU32[SP>>2], HEAPU32[RP>>2]]);" cr
   ." switch (HEAPU32[word+24>>2]|0) {" cr
   ." case 0:" cr
   dump-snippets
   ." }" cr
   ." word = HEAPU32[IP>>2]|0;" cr
   ." IP = IP+4|0;" cr
   ." }" cr
   ." }" cr
   ." return { main: main };" cr
   ." }" cr
   ;
exe-header

: >mark   here 0 , ;
: <mark   here ;
: >resolve   here swap ! ;
: <resolve   , ;

: h-number   [ action-of number ] literal is number ;
: ?number,   if 2drop undef fatal else drop t-literal 2drop then ;
: number, ( a u -- ) 0 0 2over >number nip ?number, ;
: t-number   ['] number, is number ;

: >t-body 28 + ;

t' docol >t-body to 'docol
t' dovar >t-body to 'dovar
t' docon >t-body to 'docon
t' dodef >t-body to 'dodef
0 to 'dodoes

: h: : ;

h: '   t' ;
h: ]   only forward-refs also t-words also compiler  t-number ;
h: :   parse-name header, docol, ] ;
h: create   parse-name header, dovar, ;
h: variable   create cell allot ;
h: defer   parse-name header, dodef, t-compile abort ;
h: constant   parse-name header, docon, , ;
h: value   constant ;
h: immediate   latest >nfa dup c@ negate swap c! ;
h: to   ' >t-body ! ;
h: is   ' >t-body ! ;
h: [defined]   parse-name defined? ;
h: [undefined]   [defined] 0= ;

h: ?:   already-defined? if ignore-definition else : then ;

only forth also meta also compiler definitions previous

h: \   postpone \ ;
h: (   postpone ( ;
h: [if]   postpone [if] ;
h: [else]   postpone [else] ;
h: [then]   postpone [then] ;

h: [   target h-number ;
h: ;   t-compile exit t-[compile] [ ;

h: [']   ' t-literal ;
h: [char]   char t-literal ;
h: literal   t-literal ;
h: compile   ' t-literal t-compile , ;
h: [compile]   ' , ;
h: does>   t-compile (does>) ;

cell-size t-constant cell
next-offset t-constant TO_NEXT
24 t-constant TO_CODE
28 t-constant TO_BODY
20 t-constant TO_DOES

'docol t-constant 'docol
'dovar t-constant 'dovar
'docon t-constant 'docon
'dodef t-constant 'dodef
'dodoes t-constant 'dodoes

h: s"   t-compile (sliteral) parse" dup , ", ;
h: ."   t-[compile] s" t-compile type ;

h: if   t-compile 0branch >mark ;
h: ahead   t-compile branch >mark ;
h: then   >resolve ;

h: begin   <mark ;
h: again   t-compile branch <resolve ;
h: until   t-compile 0branch <resolve ;

h: else   t-[compile] ahead swap t-[compile] then ;
h: while    t-[compile] if swap ;
h: repeat   t-[compile] again t-[compile]  then ;

h: to   ' >t-body t-literal t-compile ! ;
h: is   t-[compile] to ;

h: do   0leaves  t-compile 2>r  t-[compile] begin ;
h: loop   t-compile (loop) t-[compile] until  here leaves@ chains!  t-compile 2rdrop ;
h: leave   t-compile branch  leaves chain, ;

h: abort"   t-[compile] if t-[compile] s" t-compile cr t-compile type
   t-compile cr t-compile abort t-[compile] then ;

\ only forth :noname 2dup type space (parsed) ; is parsed
target

include kernel.fth
include cold.fth

target

only forth also meta also t-words resolve-all-forward-refs

only forth also meta

host also meta also forth definitions

t' perform 'perform @ !
." var turnkey = " t' turnkey . ." ;" cr
." var i = 0;" cr

0 target here host also meta also target-image hex dump-target-region decimal host only forth swap 2dup js-dump ." /*" cr dump ." */" cr

." /* Meta-OK */" cr
