\ -*- forth -*- Copyright 2013, 2015-2016 Lars Brinkhoff

code cold \ function main(heap)
  HEAPU8 = new Uint8Array(heap);
  HEAPU32 = new Uint32Array(heap);

  HEAPU32[sp0_word.link.addr + 28 >> 2] = 64*1024 + 4096;
  HEAPU32[rp0_word.link.addr + 28 >> 2] = 64*1024 + 8192;
  HEAPU32[dp0_word.link.addr + 28 >> 2] = 64*1024 + 16384;
  HEAPU32[limit_word.link.addr + 28 >> 2] = 64*1024 + 256 * 1024;
  HEAPU32[latest0_word.link.addr + 28 >> 2] = turnkey_word.link.addr;
  HEAPU32[SP_word.link.addr + 28 >> 2] = 64*1024 + 4096;
  HEAPU32[RP_word.link.addr + 28 >> 2] = 64*1024 + 8192;
  var xt = words_by_name.get("turnkey_word").link.addr;
  var IP = 0;

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
    IP = RPOP ();
end-code

code dodoes ( -- addr ) ( R: -- ret )
    PUSH (word + 16 + 12);
    RPUSH (IP);
    IP = HEAPU32[word + 16 + 4 >> 2];
end-code

\ Possible, but slow, implementation of 0branch.
\ : select   0= dup invert swap rot nand invert rot rot nand invert + ;
\ : 0branch   r> dup cell+ swap @ rot select >r ;

code 0branch ( x -- )
    var addr = HEAPU32[IP>>2];
    var x = POP ();
    if (x === 0)
      IP = addr;
    else
      IP+=4;
end-code

\ This works, but is too slow.
\ create 'cell   cell ,
\ variable temp
\ : (literal)   r> temp ! temp @ temp @ 'cell @ + >r @ ;

code (literal) ( -- n )
    PUSH (HEAPU32[IP>>2]);
    IP+=4;
end-code

code ! ( x addr -- )
    var addr = POP ();
    var x = POP ();
    HEAPU32[addr>>2] = x;
    //if (addr !== 0x368 )
    //console.log(describe(addr) + " -> " + describe(x));
end-code

code @ ( addr -- x )
    var addr = POP ();
    PUSH (0);
    var val = HEAPU32[addr>>2];
    POP ();
    PUSH (val);
    if (addr === HEAPU32[sp0_word.link.addr + 28 >> 2])
        throw "stack overflow";
end-code

\ : +   begin ?dup while 2dup xor -rot and 2* repeat ;

code + ( x y -- x+y )
    var y = POP ();
    var x = POP ();
    PUSH (x + y);
end-code

\ This works, but is too slow.
\ : >r   r@ rp@ -4 + rp! rp@ ! rp@ 4 + ! ;

code >r  ( x -- ) ( R: -- x )
    var x = POP ();
    RPUSH (x);
end-code

\ This works, but is too slow.
\ : r>   rp@ 4 + @ r@ rp@ 4 + rp! rp@ ! ;

code r> ( -- x ) ( R: x -- )
    var x = RPOP ();
    PUSH (x);
end-code

code nand ( x y -- ~(x&y) )
    var y = POP ();
    var x = POP ();
    PUSH ((~(x & y))|0);
end-code

code c! ( c addr -- )
    var addr = POP ();
    var c = POP ();
    HEAPU8[addr] = c;
    //console.log(describe(addr) + " -> " + describe(c));
end-code

code c@ ( addr -- c )
    var addr = POP ();
    PUSH (HEAPU8[addr]);
end-code

code emit ( c -- )
    var c = POP ();
    putchar (c);
end-code

code bye ( ... -- <no return> )
    throw 0;
end-code

code close-file ( fileid -- ior )
    POP ();
    PUSH (0);
end-code

code open-file ( addr u mode -- fileid ior )
    var mode = POP ();
    var i;
    var u = POP ();
    var addr = POP ();
    var path = StringAt(HEAPU8, addr, u);
    var fileid = 0;

    if (path in load_address) {
       fileid = load_address[path];
       fhs[fileid] = { offset: 0 };
    }

    //console.log("opening " + path);
    PUSH (fileid);
    PUSH (fileid === 0 ? 1 : 0);
end-code

code read-file ( addr u1 fileid -- u2 ior )
    var fileid = POP ();
    var u1 = POP ();
    var addr = POP ();
    var i;

    if (fileid === 0 && (!fhs[fileid] || HEAPU8[fhs[fileid].offset] === 0)) {
       fhs[0] = { offset: 1023 * 1024 };
       for (let i = 0; i < 1024; i++)
           HEAPU8[1023 * 1024 + i] = 0;
       let str = readline();
       let len = CStringTo(str, HEAPU8, fhs[0].offset);
       HEAPU8[1024 * 1023 + len - 1] = "\n".charCodeAt(0);
       HEAPU8[1024 * 1023 + len] = 0;
    }
    var off = fhs[fileid].offset;

    for (i = 0; i < u1; i++)
        if ((HEAPU8[addr++] = HEAPU8[fileid + off + i]) == 0)
           break;

    //    if (fileid === 0) console.log("read " + StringAt(HEAPU8, fileid + off, i) + HEAPU8[fileid + off]);

    fhs[fileid].offset += i;
    PUSH (i);
    PUSH (0);
end-code
