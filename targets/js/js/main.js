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
    for (let i = 128 * 1024; i < 128 * 1024; i++)
        console.log(i + " " + HEAP[i]);
}

function resume()
{
    try {
        word = HEAP[imul(1024,1022) + 512];
        IP = HEAP[imul(1024,1022) + 513];
        SP = HEAP[imul(1024,1022) + 514];
        RP = HEAP[imul(1024,1022) + 515];
        main();
    } catch (e) {
    }
}

function main()
{
    while (true) {
        var c;
        try {
            c = HEAP[word+16+2];
            code[c]();
            word = HEAP[IP];
            IP++;
        } catch (e) {
            if (e === 0)
                throw e;
            console.log("exception " + e);
            console.log("word " + word + "/" + name(word) + " IP " + IP + " c " + c + " TOS " + HEAP[SP] + " TOR " + HEAP[RP]);
            dump_dictionary();
            console.log(e.stack);
            quit();
        }
    }
}

window.onload = () => {
    vt100 = new VT100FD(undefined, document.body);

    inputstr = "s\" fmacs/src/\" searched include fmacs.fth fmacs\n";

    try {
        word = turnkey;

        main();
    } catch (e) {
    }
};
