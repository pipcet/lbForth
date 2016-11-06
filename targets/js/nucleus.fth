\ -*- forth -*- Copyright 2013, 2015-2016 Lars Brinkhoff

code cold \ function main(IP, word)
  var xt = words_by_name.get("turnkey_word").link.addr;

  try {
  for (;;)
    {
      //dump_stack();
      //console.log("[1] IP " + describe(IP) + " xt " + describe(xt) + " " + addr_to_code.get(HEAPU32[xt+24>>2]) + " " + HEAPU32[xt+24>>2]);
      IP = addr_to_code.get(HEAPU32[xt+24>>2]) (IP, xt);
      //dump_stack();
      //console.log("[2] IP " + describe(IP) + " xt " + describe(xt) + " " + addr_to_code.get(xt));
      xt = HEAPU32[IP>>2];
      //dump_stack();
      //console.log("[3] IP " + describe(IP) + " xt " + describe(xt) + " " + addr_to_code.get(xt));
      IP+=4;
    }
    } catch(e) {
      console.log("exception: " + e);
    }

  return 0;
end-code

code exit ( R: ret -- )
    IP = HEAPU32[RP>>2]|0;
    RP = RP+4|0;
end-code

code sp@
    SP = SP-4|0;
    HEAPU32[SP>>2] = SP+4|0;
end-code

code sp!
    top = HEAPU32[SP>>2]|0;
    SP = top;
end-code

code rp@
    SP = SP-4|0;
    HEAPU32[SP>>2] = RP|0;
end-code

code rp!
    top = HEAPU32[SP>>2]|0;
    RP = top;
    SP = SP+4|0;
end-code

code dodoes ( -- addr ) ( R: -- ret )
    SP = SP-4|0;
    HEAPU32[SP>>2] = word + 28|0;
    RP = RP-4|0;
    HEAPU32[RP>>2] = IP|0;
    IP = HEAPU32[word + 16 + 4 >> 2]|0;
end-code

\ Possible, but slow, implementation of 0branch.
\ : select   0= dup invert swap rot nand invert rot rot nand invert + ;
\ : 0branch   r> dup cell+ swap @ rot select >r ;

code 0branch ( x -- )
    top = HEAPU32[SP>>2]|0;
    addr = HEAPU32[IP>>2]|0;
    SP = SP+4|0;
    if ((top|0) == 0)
      IP = addr|0;
    else
      IP=IP+4|0;
end-code

code branch
    IP = HEAPU32[IP>>2]|0;
end-code

\ This works, but is too slow.
\ create 'cell   cell ,
\ variable temp
\ : (literal)   r> temp ! temp @ temp @ 'cell @ + >r @ ;

code (literal) ( -- n )
    SP = SP-4|0;
    HEAPU32[SP>>2] = HEAPU32[IP>>2]|0;
    IP=IP+4|0;
end-code

code ! ( x addr -- )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    x = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    HEAPU32[top>>2] = x;
end-code

code @ ( addr -- x )
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = HEAPU32[top>>2]|0;
end-code

\ : +   begin ?dup while 2dup xor -rot and 2* repeat ;

code + ( x y -- x+y )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    HEAPU32[SP>>2] = (HEAPU32[SP>>2]|0)+top;
end-code

code negate
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = -top|0;
end-code

code - ( x y -- x+y )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    HEAPU32[SP>>2] = ((HEAPU32[SP>>2]|0)|0)-top|0;
end-code

\ This works, but is too slow.
\ : >r   r@ rp@ -4 + rp! rp@ ! rp@ 4 + ! ;

code >r  ( x -- ) ( R: -- x )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    RP = RP - 4|0;
    HEAPU32[RP>>2] = top|0;
end-code

\ This works, but is too slow.
\ : r>   rp@ 4 + @ r@ rp@ 4 + rp! rp@ ! ;

code r> ( -- x ) ( R: x -- )
    x = HEAPU32[RP>>2]|0;
    RP = RP+4|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = x|0;
end-code

code 2r>
    x = HEAPU32[RP>>2]|0;
    RP = RP+4|0;
    y = HEAPU32[RP>>2]|0;
    RP = RP+4|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = y|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = x|0;
end-code

code 2>r
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    y = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    RP = RP-4|0;
    HEAPU32[RP>>2] = y|0;
    RP = RP-4|0;
    HEAPU32[RP>>2] = top|0;
end-code

code c! ( c addr -- )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    c = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    HEAPU8[top] = c|0;
end-code

code c@ ( addr -- c )
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = HEAPU8[top|0]|0;
end-code

code emit ( c -- )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    foreign_putchar (top|0)|0;
end-code

\ optional words

code dup
    top = HEAPU32[SP>>2]|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = top|0;
end-code

code 0=
    top = HEAPU32[SP>>2]|0;
    if ((top|0) == 0)
        c = -1;
    else
        c = 0;
    HEAPU32[SP>>2] = c|0;
end-code

code 0<>
    top = HEAPU32[SP>>2]|0;
    if ((top|0) == 0)
        c = 0;
    else
        c = -1;
    HEAPU32[SP>>2] = c|0;
end-code

code 0<
    top = HEAPU32[SP>>2]|0;
    if (0 <= (top|0))
        c = 0;
    else
        c = -1;
    HEAPU32[SP>>2] = c|0;
end-code

code <
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    if ((top>>0) > (HEAPU32[SP>>2]>>0))
        c = -1;
    else
        c = 0;
    HEAPU32[SP>>2] = c|0;
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

code ?dup
    top = HEAPU32[SP>>2]|0;
    if (top|0) {
        SP = SP-4|0;
        HEAPU32[SP>>2] = top|0;
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
    HEAPU32[SP>>2] = (HEAPU32[SP>>2]|0) != (top>>0) ? -1 : 0;
end-code

code 1+
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = top + 1|0;
end-code

code cell+
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = top + 4|0;
end-code

code +!
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[top>>2] = (HEAPU32[top>>2]|0)+(HEAPU32[SP>>2]|0)|0;
    SP=SP+4|0;
end-code

code 2*
    top = HEAPU32[SP>>2]|0;
    HEAPU32[SP>>2] = (top|0) + (top|0)|0;
end-code

code *
    top = HEAPU32[SP>>2]|0;
    SP=SP+4|0;
    HEAPU32[SP>>2] = imul(top|0, HEAPU32[SP>>2]|0)|0;
end-code

code tuck
    top = HEAPU32[SP>>2]|0;
    SP=SP-4|0;
    HEAPU32[SP+4>>2] = HEAPU32[SP+8>>2]|0;
    HEAPU32[SP+8>>2] = top|0;
    HEAPU32[SP>>2] = top|0;
end-code

code bye ( ... -- <no return> )
    foreign_exit(0)|0;
end-code

code close-file ( fileid -- ior )
    HEAPU32[SP>>2] = 0;
end-code

code open-file ( addr u mode -- fileid ior )
    top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    y = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    c = HEAPU32[SP>>2]|0;
    SP = SP+4|0;

    addr = foreign_open_file(c|0, y|0, top|0)|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = addr|0;
    SP = SP-4|0;
    if ((addr|0) == 0)
        HEAPU32[SP>>2] = 1|0;
    else
        HEAPU32[SP>>2] = 0;
end-code

code read-file ( addr u1 fileid -- u2 ior )
    c = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    z = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    addr = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    SP = SP-12|0;

    x = HEAPU32[c+8>>2]|0;
    y = HEAPU32[c+4>>2]|0;

    if ((x|0) == (y|0)) {
       if ((HEAPU32[c+12>>2]|0) == 0)
           i = 0;
       else {
           HEAPU32[imul(1024,1022) + 512>>2] = word|0;
           HEAPU32[imul(1024,1022) + 516>>2] = IP|0;
           HEAPU32[imul(1024,1022) + 520>>2] = SP|0;
           HEAPU32[imul(1024,1022) + 524>>2] = RP|0;
           i = foreign_read_file(addr|0, z|0, c|0)|0;
       }
    } else {
       if ((z>>>0) > ((x-y)>>>0))
           z = (x-y)|0;
       for (i = 0; (i>>>0) < (z>>>0); i = (i+1)|0) {
           HEAPU8[(addr+i)|0] = HEAPU8[(c+32+y+i)|0]|0;
       }
       HEAPU32[c+4>>2] = (y + i)|0;
    }

    SP = SP+12|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = i|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = 0;
end-code
