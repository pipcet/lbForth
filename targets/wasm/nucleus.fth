also meta definitions
: hi1 host-image h-align h-here target-image code-sec @ ?dup if sec-pointer0> ! then ;
hi1
previous
target

host-image here data-start !

code dodoes
    push,
    to_stack,
    W get_local,
    1c i32.const,
    i32.add,
    set,
    rpush,
    to_rstack,
    P get_local,
    set,
    W get_local,
    14 i32.const,
    i32.add,
    i32.load,
    P set_local,
end-code

code +
    top,
    x set_local,
    pop,
    top,
    y set_local,
    to_stack,
    x get_local,
    y get_local,
    i32.add,
    set,
end-code

code sp@
    S get_local,
    -4 i32.const,
    i32.add,
    S set_local,
    S get_local,
    S get_local,
    4 i32.const,
    i32.add, i32.store,
end-code

code sp!
    S get_local, i32.load,
    S set_local,
end-code

code rp@
    push,
    to_stack,
    R get_local,
    set,
end-code

code rp!
    top,
    R set_local,
    pop,
end-code

code exit
    rtop,
    P set_local,
    rpop,
end-code

code docol
    rpush,
    to_rstack,
    P get_local,
    set,
    W get_local,
    1c i32.const,
    i32.add,
    P set_local,
end-code

code dovar
    push,
    to_stack,
    W get_local,
    1c i32.const,
    i32.add,
    set,
end-code

code docon
    push,
    to_stack,
    W get_local,
    1c i32.const,
    i32.add,
    i32.load,
    set,
end-code

code dodef
    W get_local,
    1c i32.const,
    i32.add,
    i32.load,
    W set_local,
    #total-cases @ #cases @ - 2 + br,
end-code

code 0branch
    P get_local,
    i32.load,
    x set_local,
    top,
    0 i32.const,
    i32.eq,
    if,
    x get_local,
    P set_local,
    else,
    P get_local,
    4 i32.const,
    i32.add,
    P set_local,
    end_block,
    pop,
end-code

code branch
    P get_local,
    i32.load,
    P set_local,
end-code

code (literal)
    push,
    to_stack,
    P get_local,
    i32.load,
    set,
    P get_local,
    4 i32.const,
    i32.add,
    P set_local,
end-code

code !
    top,
    x set_local,
    pop,
    top,
    y set_local,
    pop,
    x get_local,
    y get_local,
    i32.store,
end-code

code @
    to_stack,
    top,
    i32.load,
    set,
end-code

code negate
    to_stack,
    0 i32.const,
    top,
    i32.sub,
    set,
end-code

code -
    top,
    x set_local,
    pop,
    top,
    y set_local,
    to_stack,
    y get_local,
    x get_local,
    i32.sub,
    set,
end-code

code >r  ( x -- ) ( R: -- x )
    rpush,
    to_rstack,
    top,
    set,
    pop,
end-code

code r> ( -- x ) ( R: x -- )
    rtop,
    x set_local,
    rpop,
    push,
    to_stack,
    x get_local,
    set,
end-code

code 2r>
    rtop,
    x set_local,
    rpop,
    rtop,
    y set_local,
    rpop,
    push,
    to_stack,
    y get_local,
    set,
    push,
    to_stack,
    x get_local,
    set,
end-code

code 2>r
    top,
    x set_local,
    pop,
    top,
    y set_local,
    pop,
    rpush,
    to_rstack,
    y get_local,
    set,
    rpush,
    to_rstack,
    x get_local,
    set,
end-code

code c!
    top,
    addr set_local,
    pop,
    top,
    c set_local,
    pop,
    addr get_local,
    c get_local,
    i32.store8,
end-code

code c@
    top,
    addr set_local,
    to_stack,
    addr get_local,
    i32.load8_u,
    set,
end-code

code (loop)
    to_rstack,
    rtop,
    1 i32.const,
    i32.add,
    set,
    push,
    rtop,
    R get_local,
    4 i32.const,
    i32.add,
    i32.load,
    i32.ge_s,
    if,
    to_stack,
    -1 i32.const,
    set,
    else,
    to_stack,
    0 i32.const,
    set,
    end_block,
end-code

code 2rdrop
    rpop,
    rpop,
end-code

code emit
    top,
    c set_local,
    pop,
    c get_local,
    0 i32.const,
    0 i32.const,
    0 i32.const,
    foreign_putchar,
    drop,
end-code

code dup
    top,
    x set_local,
    push,
    to_stack,
    x get_local,
    set,
end-code

code 0=
    top,
    0 i32.const,
    i32.eq,
    if,
    to_stack,
    -1 i32.const,
    set,
    else,
    to_stack,
    0 i32.const,
    set,
    end_block,
end-code

code 0<>
    top,
    0 i32.const,
    i32.ne,
    if,
    to_stack,
    -1 i32.const,
    set,
    else,
    to_stack,
    0 i32.const,
    set,
    end_block,
end-code

code 0<
    top,
    0 i32.const,
    i32.lt_s,
    if,
    to_stack,
    -1 i32.const,
    set,
    else,
    to_stack,
    0 i32.const,
    set,
    end_block,
end-code

code <
    top,
    x set_local,
    pop,
    top,
    y set_local,
    x get_local,
    y get_local,
    i32.gt_s,
    if,
    to_stack,
    -1 i32.const,
    set,
    else,
    to_stack,
    0 i32.const,
    set,
    end_block,
end-code

code -rot
    top,
    x set_local,
    pop,
    top,
    y set_local,
    pop,
    top,
    z set_local,
    to_stack,
    x get_local,
    set,
    push,
    to_stack,
    z get_local,
    set,
    push,
    to_stack,
    y get_local,
    set,
end-code

code rot
    top,
    x set_local,
    pop,
    top,
    y set_local,
    pop,
    top,
    z set_local,
    to_stack,
    y get_local,
    set,
    push,
    to_stack,
    x get_local,
    set,
    push,
    to_stack,
    z get_local,
    set,
end-code

code nip
    top,
    x set_local,
    pop,
    to_stack,
    x get_local,
    set,
end-code

code drop
    pop,
end-code

code ?dup
    top,
    x set_local,
    x get_local,
    0 i32.const,
    i32.ne,
    if,
    push,
    to_stack,
    x get_local,
    set,
    end_block,
end-code

code swap
    top,
    x set_local,
    pop,
    top,
    y set_local,
    to_stack,
    x get_local,
    set,
    push,
    to_stack,
    y get_local,
    set,
end-code

code over
    push,
    to_stack,
    S get_local,
    8 i32.const,
    i32.add,
    i32.load,
    set,
end-code

code invert
    to_stack,
    top,
    -1 i32.const,
    i32.xor,
    set,
end-code

code xor
    top,
    x set_local,
    pop,
    top,
    y set_local,
    to_stack,
    x get_local,
    y get_local,
    i32.xor,
    set,
end-code

code or
    top,
    x set_local,
    pop,
    top,
    y set_local,
    to_stack,
    x get_local,
    y get_local,
    i32.or,
    set,
end-code

code and
    top,
    x set_local,
    pop,
    top,
    y set_local,
    to_stack,
    x get_local,
    y get_local,
    i32.and,
    set,
end-code

code nand
    top,
    x set_local,
    pop,
    top,
    y set_local,
    to_stack,
    x get_local,
    y get_local,
    i32.and,
    -1 i32.const,
    i32.xor,
    set,
end-code

code =
    top,
    x set_local,
    pop,
    top,
    x get_local,
    i32.eq,
    if,
    to_stack,
    -1 i32.const,
    set,
    else,
    to_stack,
    0 i32.const,
    set,
    end_block,
end-code

code <>
    top,
    x set_local,
    pop,
    top,
    x get_local,
    i32.eq,
    if,
    to_stack,
    0 i32.const,
    set,
    else,
    to_stack,
    -1 i32.const,
    set,
    end_block,
end-code

code 1+
    top,
    x set_local,
    to_stack,
    x get_local,
    1 i32.const,
    i32.add,
    set,
end-code

code +!
    top,
    x set_local,
    pop,
    top,
    y set_local,
    pop,
    x get_local,
    x get_local,
    i32.load,
    y get_local,
    i32.add,
    i32.store,
end-code

code 2*
    top,
    x set_local,
    to_stack,
    x get_local,
    x get_local,
    i32.add,
    set,
end-code

code *
    top,
    x set_local,
    pop,
    top,
    y set_local,
    to_stack,
    x get_local,
    y get_local,
    i32.mul,
    set,
end-code

code tuck
    top,
    x set_local,
    push,
    S get_local,
    4 i32.const,
    i32.add,
    S get_local,
    8 i32.const,
    i32.add,
    i32.load,
    i32.store,
    S get_local,
    8 i32.const,
    i32.add,
    x get_local,
    i32.store,
    to_stack,
    x get_local,
    set,
end-code

code bye
    0 i32.const,
    0 i32.const,
    0 i32.const,
    0 i32.const,
    foreign_bye,
    drop,
end-code

code close-file
    to_stack,
    0 i32.const,
    set,
end-code

code open-file
    top,
    x set_local,
    pop,
    top,
    y set_local,
    pop,
    top,
    addr set_local,
    x get_local,
    y get_local,
    addr get_local,
    S get_local,
    foreign_open_file,
    addr set_local,
    to_stack,
    addr get_local,
    set,
    push,
    addr get_local,
    0 i32.const,
    i32.eq,
    if,
    to_stack,
    1 i32.const,
    set,
    else,
    to_stack,
    0 i32.const,
    set,
    end_block,
end-code

code read-file
    top,
    x set_local,
    pop,
    top,
    y set_local,
    pop,
    top,
    addr set_local,
    to_stack,
    x get_local,
    y get_local,
    addr get_local,
    0 i32.const,
    foreign_read_file,
    set,
    push,
    to_stack,
    0 i32.const,
    set,
    0B byte,
end-code

host-image here
also meta definitions
: hi2 code-sec @ ?dup if sec-pointer1> ! then ;
hi2
previous
target

0 code-sec !