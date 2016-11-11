\ -*- forth -*- Copyright 2013, 2015-2016 Lars Brinkhoff

code exit
    IP = HEAP[RP];
    RP++;
end-code

code sp@
    SP--;
    HEAP[SP] = SP+1;
end-code

code sp!
    var top = HEAP[SP];
    SP = top;
end-code

code rp@
    SP--;
    HEAP[SP] = RP;
end-code

code r@
    SP--;
    HEAP[SP] = HEAP[RP];
end-code

code rp!
    var top = HEAP[SP];
    RP = top;
    SP++;
end-code

code dodoes ( -- addr ) ( R: -- ret )
    SP--;
    HEAP[SP] = word + 19;
    RP--;
    HEAP[RP] = IP;
    IP = HEAP[word + 16 + 1];
end-code

code 0branch ( x -- )
    var top = HEAP[SP];
    var addr = HEAP[IP];
    SP++;
    if ((top) == 0)
      IP = addr;
    else
      IP++;
end-code

code branch
    IP = HEAP[IP];
end-code

code (literal) ( -- n )
    SP--;
    HEAP[SP] = HEAP[IP];
    IP++;
end-code

code ! ( x addr -- )
    var top = HEAP[SP];
    SP++;
    var x = HEAP[SP];
    SP++;
    HEAP[top] = x;
end-code

code @ ( addr -- x )
    var top = HEAP[SP];
    HEAP[SP] = HEAP[top];
end-code

code + ( x y -- x+y )
    var top = HEAP[SP];
    SP = SP+1;
    HEAP[SP] = (HEAP[SP])+top;
end-code

code negate
    var top = HEAP[SP];
    HEAP[SP] = -top;
end-code

code - ( x y -- x+y )
    var top = HEAP[SP];
    SP = SP+1;
    HEAP[SP] = ((HEAP[SP]))-top;
end-code

code >r  ( x -- ) ( R: -- x )
    var top = HEAP[SP];
    SP = SP+1;
    RP = RP - 1;
    HEAP[RP] = top;
end-code

code r> ( -- x ) ( R: x -- )
    var x = HEAP[RP];
    RP = RP+1;
    SP = SP-1;
    HEAP[SP] = x;
end-code

code 2r>
    var x = HEAP[RP];
    RP = RP+1;
    var y = HEAP[RP];
    RP = RP+1;
    SP = SP-1;
    HEAP[SP] = y;
    SP = SP-1;
    HEAP[SP] = x;
end-code

code 2>r
    var top = HEAP[SP];
    SP = SP+1;
    var y = HEAP[SP];
    SP = SP+1;
    RP = RP-1;
    HEAP[RP] = y;
    RP = RP-1;
    HEAP[RP] = top;
end-code

code c! ( c addr -- )
    var top = HEAP[SP];
    SP = SP+1;
    var c = HEAP[SP];
    SP = SP+1;
    HEAP[top] = c&255;
end-code

code c@ ( addr -- c )
    var top = HEAP[SP];
    HEAP[SP] = HEAP[top]&255;
end-code

code emit ( c -- )
    var top = HEAP[SP];
    SP = SP+1;
    foreign_putchar (top);
end-code

code dup
    var top = HEAP[SP];
    SP = SP-1;
    HEAP[SP] = top;
end-code

code 0=
    var top = HEAP[SP];
    //console.log(top + "0=");
    var c;
    if ((top) == 0)
        c = -1;
    else
        c = 0;
    HEAP[SP] = c;
end-code

code 0<
    var top = HEAP[SP];
    var c;
    if (0 <= (top))
        c = 0;
    else
        c = -1;
    HEAP[SP] = c;
end-code

code <
    var top = HEAP[SP];
    SP = SP+1;
    //console.log(top + " < " + HEAP[SP]);
    var c;
    if ((top) > (HEAP[SP]))
        c = -1;
    else
        c = 0;
    HEAP[SP] = c;
end-code

code rot
    var top = HEAP[SP];
    HEAP[SP] = HEAP[SP+2];
    HEAP[SP+2] = HEAP[SP+1];
    HEAP[SP+1] = top;
end-code

code -rot
    var top = HEAP[SP];
    HEAP[SP] = HEAP[SP+1];
    HEAP[SP+1] = HEAP[SP+2];
    HEAP[SP+2] = top;
end-code

code nip
    var top = HEAP[SP];
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
    var top = HEAP[SP];
    SP=SP-2;
    HEAP[SP+1] = HEAP[SP+3];
    HEAP[SP] = top;
end-code

code (loop)
    var W = HEAP[RP]+1;
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
    var top = HEAP[SP];
    if (top) {
        SP = SP-1;
        HEAP[SP] = top;
    }
end-code

code swap
    var top = HEAP[SP];
    HEAP[SP] = HEAP[SP+1];
    HEAP[SP+1] = top;
end-code

code over
    SP = SP-1;
    HEAP[SP] = HEAP[SP+2];
end-code

code invert
    var top = HEAP[SP];
    HEAP[SP] = ~top;
end-code

code xor ( x y -- x^y )
    var top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = HEAP[SP]^top;
end-code

code or
    var top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = HEAP[SP]|top;
end-code

code and ( x y -- x&y )
    var top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = HEAP[SP]&top;
end-code

code nand ( x y -- ~(x&y) )
    var top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = ~(HEAP[SP]&top);
end-code

code =
    var top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = (HEAP[SP]) == (top>>0) ? -1 : 0;
end-code

code <>
    var top = HEAP[SP];
    SP=SP+1;
    //console.log(HEAP[SP] + " <> " + top);
    HEAP[SP] = ((HEAP[SP]) != (top)) ? -1 : 0;
end-code

code 1+
    var top = HEAP[SP];
    HEAP[SP] = top + 1;
end-code

code cell+
    var top = HEAP[SP];
    HEAP[SP] = top + 1;
end-code

code +!
    var top = HEAP[SP];
    SP=SP+1;
    HEAP[top] = (HEAP[top])+(HEAP[SP]);
    SP=SP+1;
end-code

code 2*
    var top = HEAP[SP];
    HEAP[SP] = (top) + (top);
end-code

code *
    var top = HEAP[SP];
    SP=SP+1;
    HEAP[SP] = imul(top, HEAP[SP]);
end-code

code tuck
    var top = HEAP[SP];
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
    var top = HEAP[SP];
    SP = SP+1;
    var y = HEAP[SP];
    SP = SP+1;
    var c = HEAP[SP];
    SP = SP+1;
    SP -= 3;

    HEAP[imul(1024,1022) + 512] = word;
    HEAP[imul(1024,1022) + 513] = IP;
    HEAP[imul(1024,1022) + 514] = SP;
    HEAP[imul(1024,1022) + 515] = RP;
    var addr = foreign_open_file(c, y, top);
    SP += 3;
    SP = SP-1;
    HEAP[SP] = addr;
    SP = SP-1;
    if ((addr) == 0)
        HEAP[SP] = 1;
    else
        HEAP[SP] = 0;
end-code

code read-file ( addr u1 fileid -- u2 ior )
    var c = HEAP[SP];
    SP = SP+1;
    var z = HEAP[SP];
    SP = SP+1;
    var addr = HEAP[SP];
    SP = SP+1;
    SP = SP-3;

    var x = HEAP[c+2];
    var y = HEAP[c+1];

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
       }
    } else {
       if ((z>>>0) > ((x-y)>>>0))
           z = (x-y);
       for (i = 0; (i>>>0) < (z>>>0); i = (i+1)) {
           HEAP[(addr+i)] = HEAP[(c+32+y+i)];
       }
       HEAP[c+1] = (y + i);
    }

    SP = SP+3;
    SP = SP-1;
    HEAP[SP] = i;
    SP = SP-1;
    HEAP[SP] = 0;
end-code

code js-to-string
    var x = HEAP[SP];
    SP++;
    var s = x.toString();
    for (let i = 0; i < s.length; i++)
        HEAP[1021*1024+i] = s.charCodeAt(i);
    SP--;
    HEAP[SP] = 1021 * 1024;
    SP--;
    HEAP[SP] = s.length;
end-code

code js-eval-string
    var u = HEAP[SP];
    SP++;
    var a = HEAP[SP];
    SP++;
    var s = "";
    for (let i = 0; i < u; i++)
        s += String.fromCharCode(HEAP[a+i]);
    SP--;
    HEAP[SP] = eval(s);
end-code

code js-[]
    var u = HEAP[SP];
    SP++;
    var a = HEAP[SP];
    SP++;
    var o = HEAP[SP];
    SP++;
    var s = "";
    for (let i = 0; i < u; i++)
        s += String.fromCharCode(HEAP[a+i]);
    SP--;
    HEAP[SP] = o[s];
end-code

code js-global
    SP--;
    HEAP[SP] = global;
end-code

code js-call
    var n = HEAP[SP];
    SP++;
    var f = HEAP[SP];
    SP++;
    var args = [];
    for (let i = 0; i < n; i++)
        args.push(HEAP[SP++]);
    SP--;
    HEAP[SP] = f.apply(undefined, args);
end-code
