"use strict";

var heap;
var HEAPU8;
var HEAPU32;

var docolcomma4_ip = ["docolcomma", 4 + 7];

var snippets = {};

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

/* heap fs */

var next_load_address = 512 * 1024;
var load_address = {};
var load_size = {};
var fhs = {};
var gFileId = 1;

function load_file(heapu8, path)
{
    var str = os.file.readFile(path, "utf-8");
    next_load_address += 31;
    next_load_address &= -32;
    load_size[path] = CStringTo(str, heapu8, next_load_address + 32);
    load_address[path] = next_load_address;;
    HEAPU32[next_load_address+4>>2] = 0; // position
    HEAPU32[next_load_address+8>>2] = load_size[path]-1; // size
    HEAPU32[next_load_address+12>>2] = 0; // call slow_read flag
    next_load_address += 32 + load_size[path];
}

function load_files(heapu8)
{
    load_file(heapu8, "src/load.fth");
    load_file(heapu8, "src/core.fth");
    load_file(heapu8, "src/core-ext.fth");
    load_file(heapu8, "src/string.fth");
    load_file(heapu8, "src/tools.fth");
    load_file(heapu8, "src/file.fth");
}

/* console I/O */

var gLine = "";

function foreign_putchar(c)
{
    if (c == 10) {
        console.log(gLine);
        gLine = "";
    } else {
        gLine += String.fromCharCode(c);
    }
}

var putchar = foreign_putchar;

/* word linker */

var words = new Set();
var words_by_name = new Map();
var addr_to_code = new Map();
var code_to_addr = new Map();

function Word()
{
    this.prelink = {};
    this.link = {};
    words.add(this);
}

Word.prototype.calc_space = function ()
{
    return 28 + 4 * this.prelink.param.length;
};

function link0()
{
    words = [...words];
    for (let i in words) {
        words[i].link.index = +i;
        words_by_name.set(words[i].prelink.name, words[i]);
        words_by_name.set(words[i].prelink.mname, words[i]);
        words_by_name.set(words[i].prelink.name + "_word", words[i]);
        words_by_name.set(words[i].prelink.mname + "_word", words[i]);
    }
}
var end_of_words = 0;

var gIDMap = new Map();

function get_id(code)
{
    if (!gIDMap.has(code)) {
        gIDMap.set(code, gIDMap.size);
        //console.log(code + " resolves to " + gIDMap.get(code));
    }
    return gIDMap.get(code);
}

function link1()
{
    var off = 16;
    for (let w of words) {
        w.link.addr = off;
        if (w.prelink.code === 0)
            w.prelink.code = dodoes_code;
        var fakeaddr = get_id(w.prelink.code);
        addr_to_code.set(fakeaddr, w.prelink.code);
        code_to_addr.set(w.prelink.code, fakeaddr);
        off += w.calc_space();
    }
    end_of_words = off;
}

function resolve2(pair)
{
    //console.log("resolving " + pair);
    if (typeof pair === "number")
        return pair;

    if (typeof pair === "function") {
        //console.log(pair + " reseolves to " + code_to_addr.get(pair));
        return code_to_addr.get(pair);
    }

    //console.log("resolve2 " + pair[0] + " " + pair[1] + " = " + words_by_name.get(pair[0]).link.addr + " + 28 + pair[1]*4 back to " + words_by_name.get(pair[0]).prelink.name);
    return words_by_name.get(pair[0]).link.addr + pair[1]*4;
}

function link2()
{
    for (let w of words) {
        w.link.does = resolve2(w.prelink.does);
        w.link.param = w.prelink.param.map(resolve2);
        //console.log("W " + w.prelink.name + " " + w.link.param + " " + w.prelink.param);
    }
}

function resolve3(name)
{
    if (typeof name === "number")
        return name;

    return words_by_name.get(name).link.addr;
}

function save3(heapu8, heapu32)
{
    for (let w of words) {
        let a = w.link.addr;
        heapu8[a] = w.prelink.nlen;
        for (let i = 0; i < 15; i++)
            heapu8[a + i + 1] = w.prelink.name.charCodeAt(i);
        heapu32[a + 16 >> 2] = resolve3(w.prelink.next);
        heapu32[a + 20 >> 2] = w.link.does;
        heapu32[a + 24 >> 2] = get_id(w.prelink.code);
        //console.log((a + 20) + " -> " + w.link.does);
        for (let i = 0; i < w.link.param.length; i++) {
            //onsole.log("w " + w.prelink.name + " i " + i + " a " + a +
            //            " @ " + (a + 28 + 4 * i) + " = " + describe(w.link.param[i]));
            heapu32[a + 28 + 4 * i >> 2] = w.link.param[i];
        }
    }
}

function run()
{
    link0();
    link1();
    link2();
    heap = new ArrayBuffer(1024 * 1024);
    HEAPU8 = new Uint8Array(heap);
    HEAPU32 = new Uint32Array(heap);
    save3(HEAPU8, HEAPU32);
    load_files(HEAPU8);
    init_fvec();
    init_vars();
    main();
}

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

/* macro replacements */

function PUSH(val)
{
    val = val|0;
    HEAPU32[SP_word.link.addr + 28 >> 2] =
        ((HEAPU32[SP_word.link.addr + 28 >> 2]|0) - 4|0);
    HEAPU32[HEAPU32[SP_word.link.addr + 28 >> 2] >> 2] = val|0;
}
function RPUSH(val)
{
    val = val|0;
    HEAPU32[RP_word.link.addr + 28 >> 2] =
        (HEAPU32[RP_word.link.addr + 28 >> 2]|0) - 4|0;
    HEAPU32[HEAPU32[RP_word.link.addr + 28 >> 2] >> 2] = val|0;
}

function POP()
{
    var ret = 0;
    ret = HEAPU32[HEAPU32[SP_word.link.addr + 28 >> 2] >> 2]|0;
    HEAPU32[SP_word.link.addr + 28 >> 2] =
        (HEAPU32[SP_word.link.addr + 28 >> 2]|0) + 4|0;

    return ret|0;
}
function RPOP()
{
    var ret = 0;
    ret = HEAPU32[HEAPU32[RP_word.link.addr + 28 >> 2] >> 2]|0;
    HEAPU32[RP_word.link.addr + 28 >> 2] =
        (HEAPU32[RP_word.link.addr + 28 >> 2]|0) + 4|0;

    return ret|0;
}

function TOP()
{
    var ret = 0;
    ret = HEAPU32[HEAPU32[SP_word.link.addr + 28 >> 2] >> 2]|0;
    return ret|0;
}

function TOP2()
{
    var ret = 0;
    ret = HEAPU32[(HEAPU32[SP_word.link.addr + 28 >> 2]|0) + 4 >> 2]|0;
    return ret|0;
}

function SETTOP(val)
{
    val = val|0;
    HEAPU32[HEAPU32[SP_word.link.addr + 28 >> 2] >> 2] = val|0;
}

function init_vars()
{
    HEAPU32[sp0_word.link.addr + 28 >> 2] = 64*1024 + 4096;
    HEAPU32[rp0_word.link.addr + 28 >> 2] = 64*1024 + 8192;
    HEAPU32[dp0_word.link.addr + 28 >> 2] = 64*1024 + 16384;
    HEAPU32[limit_word.link.addr + 28 >> 2] = 64*1024 + 256 * 1024;
    HEAPU32[latest0_word.link.addr + 28 >> 2] = turnkey_word.link.addr;
    HEAPU32[SP_word.link.addr + 28 >> 2] = 64*1024 + 4096;
    HEAPU32[RP_word.link.addr + 28 >> 2] = 64*1024 + 8192;

    HEAPU32[0 >> 2] = words_by_name.get("turnkey_word").link.addr;
    HEAPU32[4 >> 2] = 0;
    HEAPU32[8 >> 2] = 0;
    HEAPU32[12 >> 2] = 1;
}

var fvec;

function asmmain()
{
    var xt = 0;
    var IP = 0;

    xt = HEAPU32[0>>2]|0;

    while (1|0) {
        IP = fvec[(HEAPU32[xt+24>>2]|0)&31](IP|0, xt|0)|0;
        xt = HEAPU32[IP>>2]|0;
        IP = IP + 4|0;
    }
}

snippets.asmmain0 = `
function asmmain(word, IP, SP, RP)
{
    word = word|0;
    IP = IP|0;
    SP = SP|0;
    RP = RP|0;
    var addr = 0;
    var x = 0;
    var y = 0;
    var z = 0;
    var c = 0;
    var i = 0;
    var top = 0;

    while (1|0) {
        top = HEAPU32[SP>>2]|0;
        switch (HEAPU32[word+24>>2]|0) {
`;

snippets.asmmain1 = `
        }
        word = HEAPU32[IP>>2]|0;
        IP = IP + 4|0;
    }
}`;

function init_snippets() {
    for (let [code, index] of gIDMap) {
        code = code.toString().replace(/^function [a-zA-Z0-9_]*/, "function f_" + index);
        code = code.replace("function f_" + index + "(IP, word)\n{", "case " + index + ":\n");
        code = code.replace(/}$/, "break;");
        snippets[index] = code;
    }
}

var dump = true;

function asmjs_table()
{
    console.log("var fvec = [");
    for (let i = 0; i < 32; i++)
        console.log("f_" + i + ",");
    console.log("];");
}

//while (gIDMap.size & (gIDMap.size-1))
//    get_id(function (IP, word) { IP = IP|0; word = word|0; return IP|0; });

function init_fvec() {
    fvec = [];
    for (let i = 0; i < 32; i++) {
        fvec[i] = addr_to_code.get(i);
    }
}

if (dump) {
    run = () => {
        link0();
        link1();
        init_snippets();
        link2();
        var heap = new ArrayBuffer(1024 * 1024);
        HEAPU8 = new Uint8Array(heap);
        HEAPU32 = new Uint32Array(heap);
        save3(HEAPU8, HEAPU32);
        init_vars();
        console.log("function clog(addr)");
        console.log("{ console.log(CStringAt(HEAPU8, addr)); }");
        console.log("var heap = new ArrayBuffer(1024 * 1024);");
        console.log("var HEAPU8 = new Uint8Array(heap);");
        console.log("var HEAPU32 = new Uint32Array(heap);");
        console.log(`
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

var next_load_address = 512 * 1024;
var load_address = {};
var load_size = {};
var fhs = {};
var gFileId = 1;

function load_file(heapu8, path)
{
    var str = os.file.readFile(path, "utf-8");
    next_load_address += 31;
    next_load_address &= -32;
    load_size[path] = CStringTo(str, heapu8, next_load_address + 32);
    load_address[path] = next_load_address;;
    HEAPU32[next_load_address+4>>2] = 0; // position
    HEAPU32[next_load_address+8>>2] = load_size[path]-1; // size
    HEAPU32[next_load_address+12>>2] = 0; // call slow_read flag
    next_load_address += 32 + load_size[path];
}

function load_files(heapu8)
{
    load_file(heapu8, "src/load.fth");
    load_file(heapu8, "src/core.fth");
    load_file(heapu8, "src/core-ext.fth");
    load_file(heapu8, "src/string.fth");
    load_file(heapu8, "src/tools.fth");
    load_file(heapu8, "src/file.fth");
}

//load_files(HEAPU8);

var gLine = "";

function foreign_putchar(c)
{
    console.log("putchar " + c);
    if (c == 10) {
        console.log(gLine);
        gLine = "";
    } else {
        gLine += String.fromCharCode(c);
    }

    return 0;
}

var startDate = new Date();

function foreign_exit(c)
{
    console.log((new Date())- startDate);
}


function foreign_open_file(addr, u, mode)
{
    var path = StringAt(HEAPU8, addr, u);
    var mode = CStringAt(HEAPU8, mode);

    var fileid = 0;

    if (path in load_address) {
       fileid = load_address[path];
       fhs[fileid] = { offset: 0 };
    }

    console.log("fileid " + fileid);

    return fileid;
}

function foreign_read_file(addr, u1, fileid)
{
    var i;

    if (fileid === 0 && (!fhs[fileid] || HEAPU8[fhs[fileid].offset + 32] === 0)) {
       fhs[0] = { offset: 1023 * 1024 };
       for (let i = 0; i < 1024; i++)
           HEAPU8[1023 * 1024 + i] = 0;
       let str;
       do {
           str = readline();
       } while (str === "");
       if (!str)
           throw 0;
       let len = CStringTo(str, HEAPU8, fhs[0].offset + 32);
       HEAPU8[1024 * 1023 + 32 + len - 1] = "\\n".charCodeAt(0);
       HEAPU8[1024 * 1023 + 32 + len] = 0;
    }
    var off = fhs[fileid].offset;

    for (i = 0; i < u1; i++)
        if ((HEAPU8[addr++] = HEAPU8[fileid + off + 32 + i]) == 0)
           break;

    console.log("read " + i + "/" + u1 + " " + StringAt(HEAPU8, fileid + off + 32, i) + HEAPU8[fileid + off + 32]);

    fhs[fileid].offset += i;
    return i;
}

`);
        //console.log("options(\"throw_on_asmjs_validation_failure\");");
        console.log("var gLine = \"\";");
        load_files(HEAPU8);
        console.log("load_address = {");
        for (let addr in load_address) {
            console.log("    \"" + addr + "\": " + load_address[addr] + ",");
        }
        console.log("};");
        console.log(putchar);

        console.log("function lbForth(stdlib, foreign, buffer)");
        console.log("{");
        console.log("    \"use asm\";");
        console.log("    var HEAPU8 = new stdlib.Uint8Array(buffer);")
        console.log("    var HEAPU32 = new stdlib.Uint32Array(buffer);")
        console.log("    var imul = stdlib.Math.imul;");
        console.log("    var foreign_putchar = foreign.putchar;");
        console.log("    var foreign_open_file = foreign.open_file;");
        console.log("    var foreign_read_file = foreign.read_file;");
        console.log("    var foreign_exit = foreign.exit;");

        console.log(snippets.asmmain0);
        for (let i = 0; i + "" in snippets; i++)
            console.log(snippets[i]);
        console.log(snippets.asmmain1);

        //asmjs_table();
        console.log("return { asmmain: asmmain };");
        console.log("}");


        for (let i = 0; i < 1024 * 1024; i++) {
            if (HEAPU8[i])
                console.log("HEAPU8[" + i + "] = " + HEAPU8[i] + "; // " + describe(i));
        }

        console.log("try { lbForth({ Uint8Array: Uint8Array, Uint32Array: Uint32Array, Math: Math }, { clog: clog, putchar: foreign_putchar, open_file: foreign_open_file, read_file: foreign_read_file, exit: foreign_exit }, heap).asmmain(HEAPU32[0 >> 2]|0, 0, 64*1024 + 4096, 64*1024 + 8192) } catch (e) { console.log(e)}");
    }
}
