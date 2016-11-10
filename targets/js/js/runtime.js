function clog(addr)
{
    console.log(CStringAt(HEAP, addr));
}

var next_load_address = 512 * 1024;
var load_size = {};
var fhs = {};
var gFileId = 1;
var HEAP;

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

var gLine = "";

function foreign_putchar(c)
{
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
