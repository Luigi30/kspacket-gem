	public strcpy
	public strcat

strcpy:
	;a0 = destination
	;a1 = source
.loop:
	move.b	(a1)+, (a0)+
	cmp.b	#0, (-1)(a0) ;did we just copy a null?
	bne		.loop ;no

.done:
	RTS

strcat:
	;a0 = destination
	;a1 = source
	
	;find the null terminator of a0
.findNull:
	cmp.b	#0, (a0)
	beq		.foundNull
	add.l	#1, a0
	jmp		.findNull

.foundNull:
	;a0 is now the character after the null so we can start copying
	JSR	strcpy

	RTS

sprintf:
	;parameters: destination, string, interpolation
	RTS
