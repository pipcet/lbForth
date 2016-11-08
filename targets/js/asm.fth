\ "Assembler" for C target.

\ Adds to FORTH vocabulary: ASSEMBLER CODE.
\ Creates ASSEMBLER vocabulary.

\ vocabulary assembler
\ also assembler definitions

create code-line 128 allot

: c-function ( a -- )
   ." xt_t * REGPARM " count type ." _code (xt_t *IP, struct word *word)" cr
   ." {" cr ;

: c-line ( -- a u flag )    refill 0= abort" End of file inside CODE."
   code-line dup 128 accept  2dup s" end-code" compare ;

\ previous definitions  also assembler

: .code1   ." function " latestxt >name type
   ." _code (IP, word)" cr s" " latestxt ;

create snippets 0 , 0 , reveal

: code
   get-current
   host
   ['] snippets set-current
   create
   #code @ ,
   begin refill 0= abort" Refill?" source s" end-code" compare
   while source move, 10 c, repeat refill drop
   0 c, reveal set-current
   target
   latestxt >name header, 0 , ?code, reveal ;

create rsnippets 0 , 0 , reveal

: create-rsnippet get-current swap ['] rsnippets set-current dup >name "create , reveal set-current -1 ;
: create-rsnippets ['] snippets ['] create-rsnippet traverse-wordlist ;

\ [ 0 ] [if]
\ : dump-rsnippet >body @ ." case " dup >body @ . ." /* " dup >name type ."  */:" cr >body cell+ begin dup c@ ?dup while emit 1+ repeat ." break;" cr drop -1 ;
\ : dump-snippets ['] rsnippets ['] dump-rsnippet traverse-wordlist ;
\ [else]
: dump-rsnippet >body @ ." code[" dup >body @ . ." /* " dup >name type ."  */] = function () {" cr >body cell+ begin dup c@ ?dup while emit 1+ repeat ." };" cr drop -1 ;
: dump-snippets ['] rsnippets ['] dump-rsnippet traverse-wordlist ;
\ [then]
: end-code   ;

\ previous
