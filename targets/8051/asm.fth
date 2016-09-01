\ Copyright 2016 Lars Brinkhoff

\ Assembler for 8051.

hex

\ Operand
\ 4 A
\ 4 #
\ 5 data addr
\ 6 @r0
\ 7 @r1
\ 8 r0
\ 9 r1
\ A r2
\ B r3
\ C r4
\ D r5
\ E r6
\ F r7

\ 00 1op inc,	\ 1-2
\ 00 0op nop,	\ 1
\ 01 jump ajmp,	\ 2
\ 02 1op ljmp,	\ 3
\ 03 0op rr,	\ 1
\ 10 1op dec,	\ 1-2
\ 10 2op jbc,	\ 3
\ 11 jump acall,	\ 2
\ 12 1op lcall,	\ 3
\ 13 0op rrc,	\ 1
\ 20 1op add,	\ 1-2
\ 20 2op jb,	\ 3
\ 22 0op ret,	\ 1
\ 23 0op rl,	\ 1
\ 30 2op jnb,	\ 3
\ 30 1op addc,	\ 1-2
\ 32 0op reti,	\ 1
\ 33 0op rlc,	\ 1
\ 40 2op orl,	\ 1-3
\ 40 1op jc,	\ 2
\ 50 2op anl,	\ 1-3
\ 50 1op jnc,	\ 2
\ 60 2op xrl,	\ 1-3
\ 60 1op jz,	\ 2
\ 70 2op mov,	\ 2-3
\ 70 1op jnz,	\ 1
\ 72 1op orl,	\ 2
\ 73 0op jmp,	\ 1
\ 80 2op mov,
\ 80 1op sjmp,	\ 2
\ 82 1op anl,	\ 2
\ 83 0op movc,	\ 1
\ 84 0op div,	\ 1
\ 90 1op subb,	\ 1-2
\ 90 1op mov,	\ 3
\ 92 1op mov,	\ 2
\ 93 0op movc,	\ 1
\ A0 2op mov,	\ 2
\ A0 1op orl,	\ 2
\ A2 1op mov,	\ 2
\ A3 0op inc,	\ 1
\ A4 0op mul,	\ 1
\ A5 (reserved)
\ B0 2op cjne,	\ 3
\ B0 1op anl,	\ 2
\ B2 1op cpl,	\ 1-2
\ C0 2op xch,	\ 1-2
\ C0 1op push,	\ 2
\ C2 1op clr,	\ 2
\ C3 1op clr,	\ 1
\ C4 1op swap,	\ 1
\ D0 2op djnz,	\ 2
\ D0 1op pop,	\ 2
\ D2 1op setb,	\ 1-2
\ D4 1op da,	\ 1
\ D6 2op xchd,	\ 1
\ E0 2op mov,	\ 1-2
\ E0 2op movx,	\ 1
\ E4 1op clr,	\ 1
\ F4 1op cpl,	\ 1

\ mov,
\	7x immediate -> operand
\	8x operand -> memory
\	90 immediate -> dptr
\	92 C -> bit
\	Ax memory -> operand
\	A2 bit -> C
\	Ex operand -> A
\	Fx A -> operand
\ movx,
\	E0	@dptr -> A
\	E2	@r0 -> A
\	E3	@r1 -> A
\	F0	A -> @dptr
\	F2	A -> @r0
\	F3	A -> @r1
\ setb,
\	D2	bit
\	D3	C
\ movc,
\	83	@A+PC -> A
\	93	@A+DPTR -> A
\ cpl,
\	B2	bit
\	B3	C
\	F4	A
\ clr,
\	C2	bit
\	C3	C
\	E4	A
\ inc,
\	0x	operand
\	A3	DPTR
\ orl,
\	4x	operand -> A
\	72	bit -> C
\	A0	/bit -> C
\ anl,
\	5x	operand -> A
\	82	bit -> C
\	B0	/bit -> C
