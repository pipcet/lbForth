"use strict";

eval(os.file.readFile("targets/asmjs/common.js"));

var snippets = {};

/* heap fs */

var next_load_address = 512 * 1024;
var load_size = {};
var fhs = {};
var gFileId = 1;

function load_file(heapu8, path, realpath)
{
    if (!realpath)
        realpath = path;
    var str = os.file.readFile(realpath, "utf-8");
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
    load_file(heapu8, "src/search.fth");
    load_file(heapu8, "fmacs.fth", "fmacs/src/fmacs.fth");

    load_file(heapu8, "tty.fth", "fmacs/src/tty.fth");
    load_file(heapu8, "vt100.fth", "fmacs/src/vt100.fth");
    load_file(heapu8, "point.fth", "fmacs/src/point.fth");
    load_file(heapu8, "format.fth", "fmacs/src/format.fth");
    load_file(heapu8, "window.fth", "fmacs/src/window.fth");
    load_file(heapu8, "display.fth", "fmacs/src/display.fth");
    load_file(heapu8, "text.fth", "fmacs/src/text.fth");
    load_file(heapu8, "kill.fth", "fmacs/src/kill.fth");
    load_file(heapu8, "keymap.fth", "fmacs/src/keymap.fth");
    load_file(heapu8, "minibuffer.fth", "fmacs/src/minibuffer.fth");
    load_file(heapu8, "bindings.fth", "fmacs/src/bindings.fth");
}

/* console I/O */

var gLine = "";

function foreign_putchar(c)
{
    putstr(String.fromCharCode(c));

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
    if (typeof pair === "number")
        return pair;

    if (typeof pair === "function") {
        return code_to_addr.get(pair);
    }

    return words_by_name.get(pair[0]).link.addr + pair[1]*4;
}

function link2()
{
    for (let w of words) {
        w.link.does = resolve2(w.prelink.does);
        w.link.param = w.prelink.param.map(resolve2);
    }
}

function loop25 ()
{
    var done = false;
    while (!done) {
        done = true;

        word:
        for (let w of words) {
                if (w.prelink.code !== dodoes_code)
                continue;

            if (w.prelink.mname === "dodoes")
                continue;

            for (let i = 0; i < w.prelink.param.length; i++) {
                let p = w.prelink.param[i];
                if (typeof p !== "object")
                    continue word;
                let [w2, n] = p;
                if (w2 === "_literal__word") {
                    if (typeof w.prelink.param[i+1] === "number") {
                        i++;
                        continue;
                    } else {
                        continue word;
                    }
                } else if (w2 === "_sliteral__word") {
                    let len = w.prelink.param[i+1];
                    let wlen = Math.floor(len + 3 / 4);
                    i += wlen + 1;
                    continue;
                }

                w2 = words_by_name.get(w2);
                if (n != 0)
                    continue word;
                if (w2.prelink.code === dodoes_code)
                    continue word;
            }

            done = false;

            let code = "RP=RP-4|0; HEAPU32[RP>>2] = IP;"
            for (let i = 0; i < w.prelink.param.length; i++) {
                let p = w.prelink.param[i];
                let [w2, n] = p;
                if (w2 === "_literal__word") {
                    code += "SP=SP-4|0; HEAPU32[SP>>2] = " + w.prelink.param[i+1] + ";\n";
                    i++;
                    continue;
                } else if (w2 === "_sliteral__word") {
                    let len = w.prelink.param[i+1];
                    let wlen = Math.floor(len + 3 / 4);
                    code += "SP=SP-8|0; HEAPU32[SP+4>>2] = " + (w.link.addr + 28 + (i + 2) * 4) + "; HEAPU32[SP>>2] = " + w.prelink.param[i+1] + ";\n";
                    i += wlen + 1;
                    continue;
                }
                w2 = words_by_name.get(w2);

                let index = get_id(w2.prelink.code);
                code += peel_snippet(snippets[get_id(w2.prelink.code)]);
            }

            let index = gIDMap.size;
            code = "case " + index + ": /*" + w.prelink.mname + "*/\n" + code + "\nbreak;\n";
            index = get_id(code);
            w.prelink.code = code;
            snippets[index] = code;
        }
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
        for (let i = 0; i < w.link.param.length; i++) {
            heapu32[a + 28 + 4 * i >> 2] = w.link.param[i];
        }
    }
}

var vt100;

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

snippets.asmmain0 = `
function lbForth(stdlib, foreign, buffer)
{
    "use asm";
    var HEAPU8 = new stdlib.Uint8Array(buffer);
    var HEAPU32 = new stdlib.Uint32Array(buffer);
    var imul = stdlib.Math.imul;
    var foreign_putchar = foreign.putchar;
    var foreign_open_file = foreign.open_file;
    var foreign_read_file = foreign.read_file;
    var foreign_exit = foreign.exit;

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

        l: while (1|0) {
            switch (HEAPU32[word+24>>2]|0) {
`;

snippets.asmmain1 = `
            }
            word = HEAPU32[IP>>2]|0;
            IP = IP + 4|0;
        }
    }
`;

function peel_snippet (code)
{
    let index = 666;
    code = code.toString().replace(/^function [a-zA-Z0-9_]*/, "function f_" + index);
    code = code.replace(/function f_[0-9]* \(IP, word\)\n{/, "")
    code = code.replace(/case [0-9]*:/, "");
    code = code.replace(/break;/, "");
    code = code.replace("cont()", "continue l");
    return code;
}

function cook_snippet (code, index)
{
    code = code.toString().replace(/^function [a-zA-Z0-9_]*/, "function f_" + index);
    code = code.replace("function f_" + index + "(IP, word)\n{", "case " + index + ":\n");
    code = code.replace(/}$/, "break;");
    code = code.replace("cont()", "continue l");
    return code;
}

function init_snippets() {
    for (let [code, index] of gIDMap) {
        code = cook_snippet(code, index);
        snippets[index] = code;
    }
}

run = () => {
    link0();
    link1();
    init_snippets();
    link2();

    loop25();
    var heap = new ArrayBuffer(1024 * 1024);
    HEAPU8 = new Uint8Array(heap);
    HEAPU32 = new Uint32Array(heap);
    save3(HEAPU8, HEAPU32);
    init_vars();
    console.log(os.file.readFile("targets/asmjs/common.js"));
    console.log(os.file.readFile("targets/asmjs/asmjs.js"));
    load_files(HEAPU8);
    console.log("load_address = {");
    for (let path in load_address) {
        console.log("    \"" + path + "\": " + load_address[path] + ",");
    }
    console.log("};");

    console.log(snippets.asmmain0);
    for (let i = 0; i + "" in snippets; i++)
        console.log(snippets[i]);
    console.log(snippets.asmmain1);

    console.log("    return { asmmain: asmmain };");
    console.log("}");


    for (let i = 0; i < 1024 * 1024; i+=4) {
        if (HEAPU32[i>>2])
            console.log("HEAPU32[" + i + ">>2] = 0x" + HEAPU32[i>>2].toString(16) + ";");
    }

    console.log(`
if (typeof window === "undefined")
    this.window = {};
window.onload = () => {
    if (typeof VT100FD !== "undefined")
        vt100 = new VT100FD(undefined, document.body);
    inputstr = ""; "include fmacs.fth\\nfmacs\\n";
    try {
        main = lbForth({ Uint8Array: Uint8Array, Uint32Array: Uint32Array, Math: Math }, { clog: clog, putchar: foreign_putchar, open_file: foreign_open_file, read_file: foreign_read_file, exit: foreign_exit }, heap).asmmain;
        main(HEAPU32[0 >> 2]|0, 0, 64*1024 + 4096, 64*1024 + 8192)
    } catch (e) {
        console.log(e);
    }
};
if (typeof document === "undefined")
    window.onload();
`);
}
