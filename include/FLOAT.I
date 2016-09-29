;Float routines

FloatToString:
	;Takes the IEEE 754 single-precision float in d0
	;and outputs a string to ScratchBuffer.
	lea		ScratchBuffer,a0
	lea		FloatBuffer,a1
	move.l	d0,FloatBuffer
	
	PUSHL	a1
	PUSHL	a0
	JSR		_hexfloat2str ;call C
	CORRECT	#8
	move.b	#$00,FloatBuffer+24 ;limit this to 12 digits until we figure out which values are invalid
	rts
