\ -*- forth -*- Copyright 2013, 2015-2016 Lars Brinkhoff

code exit
    IP = HEAP[RP];
    for (let i = 0; i < 0; i++)
        console.log(HEAP[RP+i] + " on the rstack");
    RP = RP+1;
end-code

code sp@
    SP = SP-1;
    HEAP[SP] = SP+1;
end-code

code sp!
    top = HEAP[SP];
    SP = top;
end-code

code rp@
    SP = SP-1;
    HEAP[SP] = RP;
end-code

code r@
    SP = SP-1;
    HEAP[SP] = HEAP[RP];
end-code

code rp!
    top = HEAP[SP];
    RP = top;
    SP = SP+1;
end-code

code dodoes ( -- addr ) ( R: -- ret )
    SP = SP-1;
    HEAP[SP] = word + 19;
    RP = RP-1;
    HEAP[RP] = IP;
    IP = HEAP[word + 16 + 1];
end-code

\ Possible, but slow, implementation of 0branch.
\ : select   0= dup invert swap rot nand invert rot rot nand invert + ;
\ : 0branch   r> dup cell+ swap @ rot select >r ;

code 0branch ( x -- )
    top = HEAP[SP];
    addr = HEAP[IP];
    SP = SP+1;
    if ((top) == 0)
      IP = addr;
    else
      IP=IP+1;
end-code

code branch
    IP = HEAP[IP];
end-code

\ This works, but is too slow.
\ create 'cell   cell ,
\ variable temp
\ : (literal)   r> temp ! temp @ temp @ 'cell @ + >r @ ;

code (literal) ( -- n )
    SP = SP-1;
    HEAP[SP] = HEAP[IP];
    IP=IP+1;
end-code

code ! ( x addr -- )
    top = HEAP[SP];
    SP = SP+1;
    x = HEAP[SP];
    SP = SP+1;
    HEAP[top] = x;
end-code

code @ ( addr -- x )
    top = HEAP[SP];
    HEAP[SP] = HEAP[top];
end-code

\ : +   begin ?dup while 2dup xor -rot and 2* repeat ;

code + ( x y -- x+y )
    top = HEAP[SP];
    SP = SP+1;
    HEAP[SP] = (HEAP[SP])+top;
end-code

code negate
    top = HEAP[SP];
    HEAP[SP] = -top;
end-code

code - ( x y -- x+y )
    top = HEAP[SP];
    SP = SP+1;
    HEAP[SP] = ((HEAP[SP]))-top;
end-code

\ This works, but is too slow.
\ : >r   r@ rp@ -4 + rp! rp@ ! rp@ 4 + ! ;

code >r  ( x -- ) ( R: -- x )
    top = HEAP[SP];
    SP = SP+1;
    RP = RP - 1;
    HEAP[RP] = top;
end-code

\ This works, but is too slow.
\ : r>   rp@ 4 + @ r@ rp@ 4 + rp! rp@ ! ;

code r> ( -- x ) ( R: x -- )
    x = HEAP[RP];
    RP = RP+1;
    SP = SP-1;
    HEAP[SP] = x;
end-code

code 2r>
    x = HEAP[RP];
    RP = RP+1;
    y = HEAP[RP];
    RP = RP+1;
    SP = SP-1;
    HEAP[SP] = y;
    SP = SP-1;
    HEAP[SP] = x;
end-code

code 2>r
    top = HEAP[SP];
    SP = SP+1;
    y = HEAP[SP];
    SP = SP+1;
    RP = RP-1;
    HEAP[RP] = y;
    RP = RP-1;
    HEAP[RP] = top;
end-code

code c! ( c addr -- )
    top = HEAP[SP];
    SP = SP+1;
    c = HEAP[SP];
    SP = SP+1;
    HEAP[top] = c&255;
end-code

code c@ ( addr -- c )
    top = HEAP[SP];
    HEAP[SP] = HEAP[top]&255;
end-code

code emit ( c -- )
    top = HEAP[SP];
    SP = SP+1;
    foreign_putchar (top);
end-code

\ optional words

code dup
    top = HEAP[SP];
    SP = SP-1;
    HEAP[SP] = top;
end-code

code 0=
    top = HEAP[SP];
    //console.log(top + "0=");
    if ((top) == 0)
        c = -1;
    else
        c = 0;
    HEAP[SP] = c;
end-code

code 0<
    top = HEAP[SP];
    if (0 <= (top))
        c = 0;
    else
        c = -1;
    HEAP[SP] = c;
end-code

code <
    top = HEAP[SP];
    SP = SP+1;
    //console.log(top + " < " + HEAP[SP]);
    if ((top) > (HEAP[SP]))
        c = -1;
    else
        c = 0;
    HEAP[SP] = c;
end-code

code rot
    top = HEAP[SP];
    HEAP[SP] = HEAP[SP+2];
    HEAP[SP+2] = HEAP[SP+1];
    HEAP[SP+1] = top;
end-code

code -rot
    top = HEAP[SP];
    HEAP[SP] = HEAP[SP+1];
    HEAP[SP+1] = HEAP[SP+2];
    HEAP[SP+2] = top;
end-code

code nip
    top = HEAP[SP];
    SP = SP+1;
    HEAP[SP] = top;
end-code

code drop
    SP = SP+1;
end-code

code 2drop
    SP = SP+2;
end-code

code 2dup
    top = HEAP[SP];
    SP=SP-2;
    HEAP[SP+1] = HEAP[SP+3];
    HEAP[SP] = top;
end-code

code (loop)
    W = HEAP[RP]+1;
    if (HEAP[RP+1] == W) {
        SP = SP-1;
        HEAP[SP] = -1;
    } else {
        SP = SP-1;
        HEAP[SP] = 0;
    }
    HEAP[RP] = W;
end-code

code 2rdrop
    RP = RP+2;
end-code

code ?dup
    top = HEAP[SP];
    if (top) {
        SP = SP-1;
        HEAP[SP] = top;
    }
end-code

code swap
    top = HEAP[SP];
    HEAP[SP] = HEAP[SP+1];
    HEAP[SP+1] = top;
end-code

code over
    SP = SP-1;
    HEAP[SP] = HEAP[SP+2];
end-code

code invert
    top = HEAP[SP];
    HEAP[SP] = ~top;
end-code

code xor ( x y -- x^y )
    top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = HEAP[SP]^top;
end-code

code or
    top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = HEAP[SP]|top;
end-code

code and ( x y -- x&y )
    top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = HEAP[SP]&top;
end-code

code nand ( x y -- ~(x&y) )
    top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = ~(HEAP[SP]&top);
end-code

code =
    top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = (HEAP[SP]) == (top>>0) ? -1 : 0;
end-code

code <>
    top = HEAP[SP];
    SP=SP+1;
    //console.log(HEAP[SP] + " <> " + top);
    HEAP[SP] = ((HEAP[SP]) != (top)) ? -1 : 0;
end-code

code 1+
    top = HEAP[SP];
    HEAP[SP] = top + 1;
end-code

code cell+
    top = HEAP[SP];
    HEAP[SP] = top + 1;
end-code

code +!
    top = HEAP[SP];
    SP=SP+1;
    HEAP[top] = (HEAP[top])+(HEAP[SP]);
    SP=SP+1;
end-code

code 2*
    top = HEAP[SP];
    HEAP[SP] = (top) + (top);
end-code

code *
    top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = imul(top, HEAP[SP]);
end-code

code tuck
    top = HEAP[SP];
    SP=SP-1;
    HEAP[SP+1] = HEAP[SP+2];
    HEAP[SP+2] = top;
    HEAP[SP] = top;
end-code

code bye ( ... -- <no return> )
    foreign_exit(0);
end-code

code close-file ( fileid -- ior )
    HEAP[SP] = 0;
end-code

code open-file ( addr u mode -- fileid ior )
    top = HEAP[SP];
    SP = SP+1;
    y = HEAP[SP];
    SP = SP+1;
    c = HEAP[SP];
    SP = SP+1;

    addr = foreign_open_file(c, y, top);
    SP = SP-1;
    HEAP[SP] = addr;
    SP = SP-1;
    if ((addr) == 0)
        HEAP[SP] = 1;
    else
        HEAP[SP] = 0;
end-code

code read-file ( addr u1 fileid -- u2 ior )
    c = HEAP[SP];
    SP = SP+1;
    z = HEAP[SP];
    SP = SP+1;
    addr = HEAP[SP];
    SP = SP+1;
    SP = SP-3;

    x = HEAP[c+2];
    y = HEAP[c+1];

    if ((x) == (y)) {
       if ((HEAP[c+3]) == 0) {
           console.log("file " + c + " at EOF");
           i = 0;
       } else {
           HEAP[imul(1024,1022) + 512] = word;
           HEAP[imul(1024,1022) + 513] = IP;
           HEAP[imul(1024,1022) + 514] = SP;
           HEAP[imul(1024,1022) + 515] = RP;
           i = foreign_read_file(addr, z, c);
           console.log("read " + String.fromCharCode(HEAP[addr]));
       }
    } else {
       if ((z>>>0) > ((x-y)>>>0))
           z = (x-y);
       for (i = 0; (i>>>0) < (z>>>0); i = (i+1)) {
           HEAP[(addr+i)] = HEAP[(c+32+y+i)];
           console.log("read " + String.fromCharCode(HEAP[addr+i]));
       }
       HEAP[c+1] = (y + i);
    }

    SP = SP+3;
    SP = SP-1;
    HEAP[SP] = i;
    SP = SP-1;
    HEAP[SP] = 0;
end-code
