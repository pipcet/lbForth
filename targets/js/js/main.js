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

main();
