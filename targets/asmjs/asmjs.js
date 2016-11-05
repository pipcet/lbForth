function clog(addr)
{
    console.log(CStringAt(HEAPU8, addr));
}
heap = new ArrayBuffer(1024 * 1024);
HEAPU8 = new Uint8Array(heap);
HEAPU32 = new Uint32Array(heap);

var next_load_address = 512 * 1024;
var load_size = {};
var fhs = {};
var gFileId = 1;

function load_file(heapu8, path)
{
    try {
        var str = os.file.readFile(path, "utf-8");
        next_load_address += 31;
        next_load_address &= -32;
        load_size[path] = CStringTo(str, heapu8, next_load_address + 32);
        load_address[path] = next_load_address;;
        HEAPU32[next_load_address+4>>2] = 0; // position
        HEAPU32[next_load_address+8>>2] = load_size[path]-1; // size
        HEAPU32[next_load_address+12>>2] = 0; // call slow_read flag
        next_load_address += 32 + load_size[path];
    } catch (e) {
        console.log("file not found: " + path)
    }
}

var gLine = "";

function foreign_putchar(c)
{
    putstr(String.fromCharCode(c));

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

    if (!(path in load_address))
       load_file(HEAPU8, path);

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

    if (fileid === 0 && (!fhs[fileid] || HEAPU8[fhs[fileid].offset + 32] === 0)) {
       fhs[0] = { offset: 1023 * 1024 };
       for (let i = 0; i < 1024; i++)
           HEAPU8[1023 * 1024 + i] = 0;
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
       let len = CStringTo(str, HEAPU8, fhs[0].offset + 32);
       HEAPU8[1024 * 1023 + 32 + len - 1] = 0;
    }
    var off = fhs[fileid].offset;

    for (i = 0; i < u1; i++)
        if ((HEAPU8[addr++] = HEAPU8[fileid + off + 32 + i]) == 0)
           break;

    fhs[fileid].offset += i;
    return i;
}

var gLine = "";
