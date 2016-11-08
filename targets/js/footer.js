code[0] = code[7];
HEAP[3] = 1;

var inputstr = "";
var imul = Math.imul;

function name(a)
{
    var c = HEAP[a];
    var s = "";

    while (c--)
        s += String.fromCharCode(HEAP[++a]);

    return s;
}

function dump_dictionary()
{
    for (let i = 128 * 1024; i < 133 * 1024; i++)
        console.log(i + " " + HEAP[i]);
}

function main()
{
    word = turnkey;

    while (true) {
        var c;
        try {
            c = HEAP[word+16+2];
            code[c]();
            word = HEAP[IP];
            IP++;
        } catch (e) {
            console.log("exception " + e);
            console.log("word " + word + "/" + name(word) + " IP " + IP + " c " + c + " TOS " + HEAP[SP] + " TOR " + HEAP[RP]);
            dump_dictionary();
            console.log(e.stack);
            quit();
        }
    }
}

var gLine = "";

function foreign_putchar(c)
{
    console.log(c);
    if (c == 10) {
        console.log(gLine);
        gLine = "";
    } else {
        gLine += String.fromCharCode(c);
    }

    return 0;
}

function foreign_open_file(addr, u, mode)
{
    var path = StringAt(HEAP, addr, u);
    var mode = CStringAt(HEAP, mode);
    mode = mode.substr(0, 1);

    console.log("open_file " + addr + " " + path + " " + mode + " " + u);

    var fileid = 0;

    if (!(path in load_address))
       load_file(HEAP, path);

    if (path in load_address) {
       fileid = load_address[path];
       fhs[fileid] = { offset: 0 };
    } else {
        console.log("file not found: " + path)
    }

    console.log("fileid " + fileid);

    return fileid;
}

function foreign_read_file(addr, u1, fileid)
{
    var i;

    if (fileid === 0 && (!fhs[fileid] || HEAP[fhs[fileid].offset + 32] === 0)) {
       fhs[0] = { offset: 1023 * 1024 };
       for (let i = 0; i < 1024; i++)
           HEAP[1023 * 1024 + i] = 0;
       let str;
       if (inputstr.length > 0) {
           str = inputstr.substr(0, 1);
           inputstr = inputstr.substr(1);
       } else {
           do {
               try {
                   str = readline();
               } catch (e) {
                   throw "input buffer empty";
                   str = window.prompt("lbForth:");
               }
           } while (str === "");
           if (str) str = str + "\n"
       }
       if (!str) {
           foreign_exit(0);
           throw 0;
       }
       let len = CStringTo(str, HEAP, fhs[0].offset + 32);
       HEAP[1024 * 1023 + 32 + len - 1] = 0;
    }
    var off = fhs[fileid].offset;

    for (i = 0; i < u1; i++)
        if ((HEAP[addr++] = HEAP[fileid + off + 32 + i]) == 0)
           break;

    fhs[fileid].offset += i;
    return i;
}

function load_file(heapu8, path)
{
    try {
        var str = os.file.readFile(path, "utf-8");
        next_load_address += 31;
        next_load_address &= -32;
        load_size[path] = CStringTo(str, heapu8, next_load_address + 32);
        load_address[path] = next_load_address;;
        HEAP[next_load_address+1] = 0; // position
        HEAP[next_load_address+2] = load_size[path]-1; // size
        HEAP[next_load_address+3] = 0; // call slow_read flag
        next_load_address += 32 + load_size[path];
    } catch (e) {
        console.log("file not found: " + path)
    }
}

var next_load_address = 512 * 1024;
var load_size = {};
var fhs = {};
var gFileId = 1;
var HEAP;

/* JavaScript code common to the asm.js backend and the
 * JavaScript-to-asm.js translator. */
"use strict";

var docolcomma4_ip = ["docolcomma", 4 + 19];

var heap;
var HEAP;

var main;

/* Library functions */

function CStringTo(str, heap, offset)
{
    var i0;

    for (i0 = 0; i0 < str.length; i0++) {
        heap[offset + i0] = str.charCodeAt(i0);
    }

    heap[offset + i0] = 0;

    return i0+1;
}

function CStringAt(heap, offset)
{
    var ret = '';

    for (var i0 = offset; heap[i0]; i0++) {
        ret += String.fromCharCode(heap[i0]);
    }

    return ret;
}

function StringAt(heap, offset, length)
{
    var ret = '';

    for (var i0 = offset; length--; i0++) {
        ret += String.fromCharCode(heap[i0]);
    }

    return ret;
}

var load_address = {};

/* debugging */

function dump_stack()
{
    console.log("stack @ " + HEAPU32[SP_word.link.addr + 28 >> 2] + ":");
    for (let i = HEAPU32[SP_word.link.addr + 28 >> 2]; i < HEAPU32[sp0_word.link.addr + 28 >> 2]; i += 4) {
        console.log(i + " -> " + describe(HEAPU32[i>>2]));
    }
    console.log("rstack @ " + HEAPU32[RP_word.link.addr + 28 >> 2] + ":");
    for (let i = HEAPU32[RP_word.link.addr + 28 >> 2]; i < HEAPU32[rp0_word.link.addr + 28 >> 2]; i += 4) {
        console.log(i + " -> " + describe(HEAPU32[i>>2]));
    }
}
function describe(addr)
{
    let bestword = words[0];
    let dist = +Infinity;
    for (let w of words) {
        if (w.link.addr <= addr && addr - w.link.addr < dist) {
            bestword = w;
            dist = addr - w.link.addr;
        }
    }

    return addr.toString(16) + " = " + bestword.prelink.name + " + " + dist;
}


main();

