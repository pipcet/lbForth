var next_load_address = 512 * 1024;
var load_size = {};
var fhs = {};
var gFileId = 1;
var filesystem = {};

function load_file(heapu8, path)
{
    console.log("load_file " + path);

    if (path.match(/\/$/))
        return;

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

    console.log("load_file " + path);
}

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
    mode = mode.substr(0, 1);

    console.log("open_file " + addr + " " + path + " " + mode + " " + u);

    var fileid = 0;

    if (!(path in load_address))
       load_file(HEAPU8, path);

    if (path in load_address) {
        fileid = load_address[path];
        fhs[fileid] = { offset: 0 };
    } else if (path in filesystem) {
        if ("ok" in filesystem[path]) {
            if (filesystem[path].ok) {
                next_load_address += 31;
                next_load_address &= -32;
                load_size[path] = filesystem[path].ab.byteLength;
                let u8 = new Uint8Array(filesystem[path].ab);
                HEAPU32[next_load_address+4>>2] = 0; // position
                HEAPU32[next_load_address+8>>2] = load_size[path]-1; // size
                HEAPU32[next_load_address+12>>2] = 0; // call slow_read flag
                next_load_address += 32;
                for (let i = 0; i < load_size[path]; i++)
                    HEAPU8[next_load_address+i] = u8[i];
                load_address[path] = next_load_address - 32;
                next_load_address += load_size[path];
                resume();
                throw 0;
            } else {
                console.log("fileid " + 0);
                return 0;
            }
        } else {
            throw 0;
        }
    } else if (typeof fetch !== "undefined" && !(path in filesystem)) {
        filesystem[path] = {};
        fetch(path).then(response => {
            return response.arrayBuffer();
        }).then(ab => {
            filesystem[path] = { ok: true, ab: ab };
            resume();
        }).catch(e => {
            filesystem[path] = { ok: false };
            resume();
        });

        throw 0;
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
                   console.log(e);
                   throw 0;
                   str = window.prompt("lbForth:");
               }
           } while (str === "");
           if (str) str = str + "\n"
       }
        if (!str) {
            console.log("empty string");
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

function syscall(xt, IP, SP, RP)
{
    HEAPU32[1022*1024+512>>2] = xt;
    HEAPU32[1022*1024+516>>2] = IP;
    HEAPU32[1022*1024+520>>2] = SP;
    HEAPU32[1022*1024+524>>2] = RP;
}

function foreign_sys_open(xt, IP, SP, RP)
{
    syscall(xt, IP, SP, RP);
    var top = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    var y = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    var c = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    SP = SP-12|0;

    var addr = foreign_open_file(c|0, y|0, top|0)|0;
    SP = SP+12|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = addr;
    SP = SP-4|0;
    if ((addr|0) == 0)
        HEAPU32[SP>>2] = 1;
    else
        HEAPU32[SP>>2] = 0;
}

function foreign_sys_read(xt, IP, SP, RP)
{
    syscall(xt, IP, SP, RP);
    var c = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    var z = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    var addr = HEAPU32[SP>>2]|0;
    SP = SP+4|0;
    SP = SP-12|0;

    var x = HEAPU32[c+8>>2]|0;
    var y = HEAPU32[c+4>>2]|0;
    var i = 0;

    if ((x) == (y)) {
       if ((HEAPU32[c+12>>2]|0) == 0) {
           i = 0;
       } else {
           i = foreign_read_file(addr, z, c)|0;
       }
    } else {
       if ((z>>>0) > ((x-y)>>>0))
           z = (x-y);
       for (i = 0; (i>>>0) < (z>>>0); i = (i+1)) {
           HEAPU8[(addr+i)] = HEAPU8[(c+32+y+i)]|0;
       }
       HEAPU32[c+4>>2] = (y + i);
    }

    SP = SP+12|0;
    SP = SP-4|0;
    HEAPU32[SP>>2] = i;
    SP = SP-4|0;
    HEAPU32[SP>>2] = 0;
}

function foreign_exit ()
{
    console.log("exit");
    while (1);
}
