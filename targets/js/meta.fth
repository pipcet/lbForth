\ Metacompiler for x86.  Copyright Lars Brinkhoff 2015-2016.

1 constant t-little-endian
: NAME_LENGTH 16 ;
: load-address 0 ;
: exe-header ;
s" targets/js/" searched
s" " searched
s" src/" searched
include lib/meta.fth
