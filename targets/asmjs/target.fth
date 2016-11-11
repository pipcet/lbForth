: io-init ;
: r/o   s" r" drop ;

\ If you change the definition of docol, you also need to update the
\ offset to the runtime code in the metacompiler(s).
: docol,   'docol , 0 , ;
: dovar,   'dovar , 0 , ;
: docon,   'docon , 0 , ;
: dodef,   'dodef , 0 , ;

: #name ( -- u )       16 1 - ;
: name, ( a u -- )     #name min dup c, tuck move, #name swap 2dup - if do 0 c, loop then ;
: header, ( a u -- )   align here >r name, r> link, ;

: >xt ;
: >nfa ;
: >name    >nfa count cabs ;

: noheader,   s" " header, ;
