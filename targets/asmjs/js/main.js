HEAPU32[12>>2] = 1;

var inputstr = "";
var imul = Math.imul;

function name(a)
{
    var c = HEAPU8[a];
    var s = "";

    while (c--)
        s += String.fromCharCode(HEAPU8[++a]);

    return s;
}

function dump_dictionary()
{
    for (let i = 128 * 1024; i < 129 * 1024; i+=4)
        console.log(i + " " + HEAPU32[i>>2]);
}

var foreign = {
    foreign_putchar: foreign_putchar,
    foreign_sys_open: foreign_sys_open,
    foreign_sys_read: foreign_sys_read,
    foreign_exit: foreign_exit,
};

var module = asmmodule(this, foreign, heap);
var window;

function _resume()
{
    try {
        var word = HEAPU32[imul(1024,1022) + 512>>2];
        var IP = HEAPU32[imul(1024,1022) + 516>>2];
        var SP = HEAPU32[imul(1024,1022) + 520>>2];
        var RP = HEAPU32[imul(1024,1022) + 524>>2];
        HEAPU32[1022*1024 + 512>>2] = 0;
        HEAPU32[1022*1024 + 516>>2] = 0;
        HEAPU32[1022*1024 + 520>>2] = 0;
        HEAPU32[1022*1024 + 524>>2] = 0;
        module.main(word, IP, SP, RP);
    } catch (e) {
    }
}

function resume()
{
    window.setTimeout(_resume, 0);
}

if (typeof window === "undefined")
    window = {};

window.onload = () => {
    if (typeof document !== "undefined")
        vt100 = new VT100FD(undefined, document.body);

    inputstr = "s\" fmacs/src/\" searched include fmacs.fth fmacs\n";
    inputstr = "bye\n";

    console.log("launching main");

    try {
        let word = turnkey;

        module.main(word, 0, 64*1024, 128*1024);
    } catch (e) {
    }
};

if (typeof document === "undefined")
    window.onload();
