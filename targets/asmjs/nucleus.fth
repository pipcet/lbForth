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

code rp@
    PUSH (RP|0);
end-code

code rp!
    RP = POP ()|0;
end-code

code dodoes ( -- addr ) ( R: -- ret )
    PUSH (word + 16 + 12|0);
    RP = RP-4|0;
    HEAPU32[RP>>2] = IP|0;
    IP = HEAPU32[word + 16 + 4 >> 2]|0;
end-code

\ Possible, but slow, implementation of 0branch.
\ : select   0= dup invert swap rot nand invert rot rot nand invert + ;
\ : 0branch   r> dup cell+ swap @ rot select >r ;

code 0branch ( x -- )
    addr = HEAPU32[IP>>2]|0;
    x = POP ()|0;
    if ((x|0) == 0)
      IP = addr|0;
    else
      IP=IP+4|0;
end-code

\ This works, but is too slow.
\ create 'cell   cell ,
\ variable temp
\ : (literal)   r> temp ! temp @ temp @ 'cell @ + >r @ ;

code (literal) ( -- n )
    PUSH (HEAPU32[IP>>2]|0);
    IP=IP+4|0;
end-code

code ! ( x addr -- )
    addr = POP ()|0;
    x = POP ()|0;
    HEAPU32[addr>>2] = x;
end-code

code @ ( addr -- x )
    SETTOP (HEAPU32[(TOP ()|0)>>2]|0);
end-code

\ : +   begin ?dup while 2dup xor -rot and 2* repeat ;

code + ( x y -- x+y )
    y = POP ()|0;
    x = POP ()|0;
    PUSH (x + y|0);
end-code

\ This works, but is too slow.
\ : >r   r@ rp@ -4 + rp! rp@ ! rp@ 4 + ! ;

code >r  ( x -- ) ( R: -- x )
    x = POP ()|0;
    RP = RP - 4|0;
    HEAPU32[RP>>2] = x|0;
end-code

\ This works, but is too slow.
\ : r>   rp@ 4 + @ r@ rp@ 4 + rp! rp@ ! ;

code r> ( -- x ) ( R: x -- )
    x = HEAPU32[RP>>2]|0;
    RP = RP+4|0;
    PUSH (x|0);
end-code

code nand ( x y -- ~(x&y) )
    y = POP ()|0;
    x = POP ()|0;
    PUSH ((~(x & y))|0);
end-code

code c! ( c addr -- )
    addr = POP ()|0;
    c = POP ()|0;
    HEAPU8[addr] = c|0;
end-code

code c@ ( addr -- c )
    addr = POP ()|0;
    PUSH (HEAPU8[addr]|0);
end-code

code emit ( c -- )
    c = POP ()|0;
    foreign_putchar (c|0)|0;
end-code

\ optional words

code dup
    PUSH (TOP ()|0);
end-code

code 0=
    c = TOP ()|0;
    if ((c|0) == 0)
        c = 1;
    else
        c = 0;
    SETTOP (c);
end-code

code 0<>
    c = TOP ()|0;
    if ((c|0) == 0)
        c = 0;
    else
        c = 1;
    SETTOP (c);
end-code

code drop
    POP ()|0;
end-code

code ?dup
    c = TOP ()|0;
    if (c|0)
        PUSH (c|0);
end-code

code swap
    x = POP ()|0;
    y = POP ()|0;
    PUSH (x);
    PUSH (y);
end-code

code over
    PUSH (TOP2 ()|0);
end-code

code invert
    SETTOP (~(TOP ()|0));
end-code

code xor ( x y -- x^y )
    y = POP ()|0;
    SETTOP (((TOP ()|0)^y)|0);
end-code

code or
    y = POP ()|0;
    SETTOP (((TOP ()|0)|y)|0);
end-code

code and ( x y -- x&y )
    y = POP ()|0;
    SETTOP (((TOP ()|0)&y)|0);
end-code

code bye ( ... -- <no return> )
    foreign_exit(0)|0;
end-code

code close-file ( fileid -- ior )
    POP ()|0;
    PUSH (0);
end-code

code open-file ( addr u mode -- fileid ior )
    x = POP ()|0;
    y = POP ()|0;
    c = POP ()|0;

    addr = foreign_open_file(c|0, y|0, x|0)|0;
    PUSH (addr|0);
    if ((addr|0) == 0)
        PUSH (1);
    else
        PUSH (0);
end-code

code read-file ( addr u1 fileid -- u2 ior )
    c = POP ()|0;
    z = POP ()|0;
    addr = POP ()|0;

    x = HEAPU32[c+8>>2]|0;
    y = HEAPU32[c+4>>2]|0;

    if ((x|0) == (y|0)) {
       if ((HEAPU32[c+12>>2]|0) == 0)
           i = 0;
       else
           i = foreign_read_file(addr|0, z|0, c|0)|0;
    } else {
       if ((z>>>0) > ((x-y)>>>0))
           z = (x-y)|0;
       for (i = 0; (i>>>0) < (z>>>0); i = (i+1)|0) {
           HEAPU8[(addr+i)|0] = HEAPU8[(c+32+y+i)|0]|0;
       }
       HEAPU32[c+4>>2] = (y + i)|0;
    }

    PUSH (i|0);
    PUSH (0);
end-code
