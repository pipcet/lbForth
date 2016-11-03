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
    IP = RPOP ()|0;
end-code

code dodoes ( -- addr ) ( R: -- ret )
    PUSH (word + 16 + 12|0);
    RPUSH (IP);
    IP = HEAPU32[word + 16 + 4 >> 2]|0;
end-code

\ Possible, but slow, implementation of 0branch.
\ : select   0= dup invert swap rot nand invert rot rot nand invert + ;
\ : 0branch   r> dup cell+ swap @ rot select >r ;

code 0branch ( x -- )
    var addr = 0;
    var x = 0;
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
    var x = 0;
    var addr = 0;
    addr = POP ()|0;
    x = POP ()|0;
    HEAPU32[addr>>2] = x;
end-code

code @ ( addr -- x )
    SETTOP (HEAPU32[(TOP ()|0)>>2]|0);
end-code

\ : +   begin ?dup while 2dup xor -rot and 2* repeat ;

code + ( x y -- x+y )
    var y = 0;
    var x = 0;
    y = POP ()|0;
    x = POP ()|0;
    PUSH (x + y|0);
end-code

\ This works, but is too slow.
\ : >r   r@ rp@ -4 + rp! rp@ ! rp@ 4 + ! ;

code >r  ( x -- ) ( R: -- x )
    var x = 0;
    x = POP ()|0;
    RPUSH (x|0);
end-code

\ This works, but is too slow.
\ : r>   rp@ 4 + @ r@ rp@ 4 + rp! rp@ ! ;

code r> ( -- x ) ( R: x -- )
    var x = 0;
    x = RPOP ()|0;
    PUSH (x|0);
end-code

code nand ( x y -- ~(x&y) )
    var y = 0;
    var x = 0;
    y = POP ()|0;
    x = POP ()|0;
    PUSH ((~(x & y))|0);
end-code

code c! ( c addr -- )
    var addr = 0;
    var c = 0;
    addr = POP ()|0;
    c = POP ()|0;
    HEAPU8[addr] = c|0;
end-code

code c@ ( addr -- c )
    var addr = 0;
    addr = POP ()|0;
    PUSH (HEAPU8[addr]|0);
end-code

code emit ( c -- )
    var c = 0;
    c = POP ()|0;
    foreign_putchar (c|0)|0;
end-code

\ optional words

code dup
    PUSH (TOP ()|0);
end-code

code 0=
    var c = 0;
    c = TOP ()|0;
    if ((c|0) == 0)
        c = 1;
    else
        c = 0;
    SETTOP (c);
end-code

code 0<>
    var c = 0;
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
    var v = 0;
    v = TOP ()|0;
    if (v|0)
        PUSH (v|0);
end-code

code swap
    var x = 0;
    var y = 0;
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
    var y = 0;
    y = POP ()|0;
    SETTOP (((TOP ()|0)^y)|0);
end-code

code or
    var y = 0;
    y = POP ()|0;
    SETTOP (((TOP ()|0)|y)|0);
end-code

code and ( x y -- x&y )
    var y = 0;
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
    var mode = 0;
    var i = 0;
    var u = 0;
    var addr = 0;
    var fileid = 0;
    mode = POP ()|0;
    u = POP ()|0;
    addr = POP ()|0;

    fileid = foreign_open_file(addr|0, u|0, mode|0)|0;
    PUSH (fileid|0);
    if ((fileid|0) == 0)
        PUSH (1);
    else
        PUSH (0);
end-code

code read-file ( addr u1 fileid -- u2 ior )
    var fileid = 0;
    var u1 = 0;
    var addr = 0;
    var i = 0;
    var size = 0;
    var off = 0;
    fileid = POP ()|0;
    u1 = POP ()|0;
    addr = POP ()|0;

    size = HEAPU32[fileid+8>>2]|0;
    off = HEAPU32[fileid+4>>2]|0;

    if ((off|0) == (size|0)) {
       if ((HEAPU32[fileid+12>>2]|0) == 0)
           i = 0;
       else
           i = foreign_read_file(addr|0, u1|0, fileid|0)|0;
    } else {
       if ((u1>>>0) > ((size-off)>>>0))
           u1 = (size-off)|0;
       for (i = 0; (i>>>0) < (u1>>>0); i = (i+1)|0) {
           HEAPU8[(addr+i)|0] = HEAPU8[(fileid+32+off+i)|0]|0;
       }
       HEAPU32[fileid+4>>2] = (off + i)|0;
    }

    PUSH (i|0);
    PUSH (0);
end-code
