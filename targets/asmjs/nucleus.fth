\ -*- forth -*- Copyright 2013, 2015-2016 Lars Brinkhoff

\ This has to be code 1
code dodoes ( -- addr ) ( R: -- ret )
    SP=SP-4|0;
    HEAPU32[SP>>2] = word + 28;
    RP=RP-4|0;
    HEAPU32[RP>>2] = IP;
    IP = HEAPU32[word + 16 + 4>>2]|0;
end-code

code exit
    IP = HEAPU32[RP>>2]|0;
    RP=RP+4|0;
end-code

code sp@
    SP=SP-4|0;
    HEAPU32[SP>>2] = SP+4;
end-code

code sp!
    top = HEAPU32[SP>>2]|0;
    SP = top;
end-code

code rp@
    SP=SP-4|0;
    HEAPU32[SP>>2] = RP;
end-code

code r@
    SP=SP-4|0;
    HEAPU32[SP>>2] = HEAPU32[RP>>2]|0;
end-code

code rp!
    top = HEAPU32[SP>>2]|0;
    RP = top;
    SP=SP+4|0;
end-code

code 0branch ( x -- )
    top = HEAPU32[SP>>2]|0;
    addr = HEAPU32[IP>>2]|0;
    SP=SP+4|0;
    if ((top|0) == 0)
        IP = addr;
    else
        IP=IP+4|0;
end-code

code branch
    IP = HEAPU32[IP>>2]|0;
end-code

code (literal) ( -- n )
    SP=SP-4|0;
    HEAPU32[SP>>2] = HEAPU32[IP>>2]|0;
    IP=IP+4|0;
end-code

code ! ( x addr -- )
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    x = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[top>>2] = x;
end-code

code @ ( addr -- x )
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = HEAPU32[top>>2]|0;
end-code

code + ( x y -- x+y )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    HEAPU32[SP>>2] = (HEAPU32[SP>>2]|0)+top;
end-code

code negate
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = -top;
end-code

code - ( x y -- x+y )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    HEAPU32[SP>>2] = ((HEAPU32[SP>>2]|0))-top;
end-code

code >r  ( x -- ) ( R: -- x )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    RP = RP-4|0;
    HEAPU32[RP>>2] = top;
end-code

code r> ( -- x ) ( R: x -- )
    x = HEAPU32[RP>>2]|0;
    RP = RP+4|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = x;
end-code

code 2r>
    x = HEAPU32[RP>>2]|0;
    RP = RP+4|0;
    y = HEAPU32[RP>>2]|0;
    RP = RP+4|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = y;
    SP = SP-4|0;
    HEAPU32[SP>>2] = x;
end-code

code 2>r
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    y = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    RP = RP-4|0;
    HEAPU32[RP>>2] = y;
    RP = RP-4|0;
    HEAPU32[RP>>2] = top;
end-code

code c! ( c addr -- )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    c = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    HEAPU8[top] = c&255;
end-code

code c@ ( addr -- c )
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = HEAPU8[top]|0;
end-code

code emit ( c -- )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    foreign_putchar (top|0);
end-code

code dup
    top = HEAPU32[SP>>2]|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = top;
end-code

code 0=
    top = HEAPU32[SP>>2]|0;
    if ((top|0) == 0)
        c = -1;
    else
        c = 0;
    HEAPU32[SP>>2] = c;
end-code

code 0<
    top = HEAPU32[SP>>2]|0;
    if (0 <= (top|0))
        c = 0;
    else
        c = -1;
    HEAPU32[SP>>2] = c;
end-code

code <
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    if ((top|0) > (HEAPU32[SP>>2]|0))
        c = -1;
    else
        c = 0;
    HEAPU32[SP>>2] = c;
end-code

code rot
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = HEAPU32[SP+8>>2]|0;
    HEAPU32[SP+8>>2] = HEAPU32[SP+4>>2]|0;
    HEAPU32[SP+4>>2] = top;
end-code

code -rot
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = HEAPU32[SP+4>>2]|0;
    HEAPU32[SP+4>>2] = HEAPU32[SP+8>>2]|0;
    HEAPU32[SP+8>>2] = top;
end-code

code nip
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    HEAPU32[SP>>2] = top;
end-code

code drop
    SP = SP+4|0;
end-code

code 2drop
    SP = SP+8|0;
end-code

code 2dup
    top = HEAPU32[SP>>2]|0;
    SP=SP-8|0;
    HEAPU32[SP+4>>2] = HEAPU32[SP+12>>2]|0;
    HEAPU32[SP>>2] = top;
end-code

code (loop)
    x = (HEAPU32[RP>>2]|0)+1|0;
    if ((HEAPU32[RP+4>>2]|0) == (x|0)) {
        SP = SP-4|0;
        HEAPU32[SP>>2] = -1;
    } else {
        SP = SP-4|0;
        HEAPU32[SP>>2] = 0;
    }
    HEAPU32[RP>>2] = x;
end-code

code 2rdrop
    RP = RP+8|0;
end-code

code ?dup
    top = HEAPU32[SP>>2]|0;
    if (top|0) {
        SP = SP-4|0;
        HEAPU32[SP>>2] = top;
    }
end-code

code swap
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = HEAPU32[SP+4>>2]|0;
    HEAPU32[SP+4>>2] = top;
end-code

code over
    SP = SP-4|0;
    HEAPU32[SP>>2] = HEAPU32[SP+8>>2]|0;
end-code

code invert
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = ~top;
end-code

code xor ( x y -- x^y )
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[SP>>2] = HEAPU32[SP>>2]^top;
end-code

code or
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[SP>>2] = HEAPU32[SP>>2]|top;
end-code

code and ( x y -- x&y )
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[SP>>2] = HEAPU32[SP>>2]&top;
end-code

code nand ( x y -- ~(x&y) )
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[SP>>2] = ~(HEAPU32[SP>>2]&top);
end-code

code =
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[SP>>2] = (HEAPU32[SP>>2]|0) == (top>>0) ? -1 : 0;
end-code

code <>
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[SP>>2] = ((HEAPU32[SP>>2]|0) != (top|0)) ? -1 : 0;
end-code

code 1+
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = top + 1;
end-code

code cell+
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = top + 4;
end-code

code +!
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[top>>2] = (HEAPU32[top>>2]|0)+(HEAPU32[SP>>2]|0);
    SP=SP+4|0;
end-code

code 2*
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = (top) + (top);
end-code

code *
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[SP>>2] = imul(top, HEAPU32[SP>>2]|0);
end-code

code tuck
    top = HEAPU32[SP>>2]|0;
    SP=SP-4|0;
    HEAPU32[SP+4>>2] = HEAPU32[SP+8>>2]|0;
    HEAPU32[SP+8>>2] = top;
    HEAPU32[SP>>2] = top;
end-code

code bye ( ... -- <no return> )
    foreign_exit(0);
end-code

code close-file ( fileid -- ior )
    HEAPU32[SP>>2] = 0;
end-code

code open-file ( addr u mode -- fileid ior )
    foreign_sys_open(word|0, IP|0, SP|0, RP|0)|0;
    SP = SP+4|0;
end-code

code read-file ( addr u1 fileid -- u2 ior )
    foreign_sys_read(word|0, IP|0, SP|0, RP|0)|0;
    SP = SP+4|0;
end-code
