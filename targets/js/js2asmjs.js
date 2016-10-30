var docolcomma4_ip = ["docolcomma", 4 + 7];
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
gIDMap.set(0, 0);

function get_id(code)
{
    if (!gIDMap.has(code)) {
        gIDMap.set(code, gIDMap.size);
        console.log(code + " resolves to " + gIDMap.get(code));
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
        console.log(pair + " reseolves to " + code_to_addr.get(pair));
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

function CStringTo(str, heap, offset)
{
    var i0;

    for (i0 = 0; i0 < str.length; i0++) {
        heap[offset + i0] = str.charCodeAt(i0);
    }

    heap[offset + i0] = 0;

    return i0+1;
}

var next_load_address = 512 * 1024;
var load_address = {};
var load_size = {};
var fhs = {};

function load_file(heapu8, path)
{
    var str = os.file.readFile(path, "utf-8");
    load_size[path] = CStringTo(str, heapu8, next_load_address);
    load_address[path] = next_load_address;;
    next_load_address += load_size[path];
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

function run()
{
    link0();
    link1();
    link2();
    var heap = new ArrayBuffer(1024 * 1024);
    var HEAPU8 = new Uint8Array(heap);
    var HEAPU32 = new Uint32Array(heap);
    save3(HEAPU8, HEAPU32);
    load_files(HEAPU8);

    if (false) for (let i = 0; i < 1024 * 1024; i += 4) {
        let val = HEAPU32[i>>2];
        if (val !== 0)
            console.log(describe(i) + " -> " + describe(val));
    }

    let ptr = turnkey_word.link.addr;
    let count = 0;
    while (ptr) {
        console.log(describe(ptr));
        ptr = HEAPU32[ptr+16>>2];
        count++;
    }
    console.log(count + " words");

    main(heap);
    if (false) for (let i = 0; i < 1024 * 1024; i += 4) {
        let val = HEAPU32[i>>2];
        if (val !== 0)
            console.log(describe(i) + " -> " + describe(val));
    }
}

var HEAPU8;
var HEAPU32;

function cold_code()
{
    run();
}

function PUSH(val)
{
    HEAPU32[SP_word.link.addr + 28 >> 2] -= 4;
    HEAPU32[HEAPU32[SP_word.link.addr + 28 >> 2] >> 2] = val;
}
function RPUSH(val)
{
    HEAPU32[RP_word.link.addr + 28 >> 2] -= 4;
    HEAPU32[HEAPU32[RP_word.link.addr + 28 >> 2] >> 2] = val;
}

function POP()
{
    var ret = HEAPU32[HEAPU32[SP_word.link.addr + 28 >> 2] >> 2];
    HEAPU32[SP_word.link.addr + 28 >> 2] += 4;

    return ret;
}
function RPOP()
{
    var ret = HEAPU32[HEAPU32[RP_word.link.addr + 28 >> 2] >> 2];
    HEAPU32[RP_word.link.addr + 28 >> 2] += 4;

    return ret;
}

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

var gLine = "";

function putchar(c)
{
    if (c == 10) {
        console.log(gLine);
        gLine = "";
    } else {
        gLine += String.fromCharCode(c);
    }
}
var gFileId = 1;
