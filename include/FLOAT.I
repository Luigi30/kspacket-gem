;Float routines

	SECTION CODE

	XDEF FloatToString

	even
FloatToString:
	PUSHREG d0-d7/a0-a7
	;Takes the IEEE 754 single-precision float in d0
	;and outputs a string to a0.
	move.l	d0,FloatBuffer

	;lea		ScratchBuffer,a0
	lea		FloatBuffer,a1
	lea		FloatFormat,a2
	
	PUSHL	a1
	PUSHL	a0
	JSR		_hexfloat2str ;call C

	CORRECT	#8
	move.b	#$00,ScratchBuffer+24 ;limit this to 12 digits until we figure out which values are invalid

	POPREG d0-d7/a0-a7
	rts
*************************************

        section "CODE",code
        public  _hexfloat2str
        cnop    0,4
_hexfloat2str
        movem.l l3,-(a7)
        move.l  #4,-(a7)
        move.l  (12+l5,a7),-(a7)
        pea     _f
        jsr     _memcpy
        move.l  _f,-(a7)
        jsr     __ieees2d
        movem.l d0/d1,-(a7)
        pea     l2
        move.l  (32+l5,a7),-(a7)
        jsr     _sprintf
        add.w   #32,a7
l1
l3      reg
l5      equ     0
        rts
        cnop    0,4
l2
        dc.b    37
        dc.b    49
        dc.b    48
        dc.b    46
        dc.b    50
        dc.b    102
        dc.b    0
        public  __ieees2d
        public  _sprintf
        public  _f
        section "BSS",bss
        cnop    0,4
_f
        ds.b    4
        public  _memcpy


*************************************

	SECTION DATA
FloatFormat 	dc.b 	"%10.2f"
FloatBuffer		ds.b	8
ScratchBuffer	ds.b	128
