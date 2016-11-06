/* JavaScript code common to the asm.js backend and the
 * JavaScript-to-asm.js translator. */
"use strict";

var docolcomma4_ip = ["docolcomma", 4 + 7];

var heap;
var HEAPU8;
var HEAPU32;

var inputstr = "";
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

