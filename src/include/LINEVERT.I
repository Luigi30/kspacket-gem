DrawVerticalLine:
	;d0 = y0
	;d7 = y1
	;d1 = x coord
	PUSHREG	d0

	exg		d0,d1
	move.l	GFX_BASE, a4

.loop:
	;now d0 = x coord, d1 = y coord
	JSR		PlotHiResPixel
	add.w	#1, d1
	cmp		d1, d7
	bne		.loop

	POPREG	d0
	RTS
