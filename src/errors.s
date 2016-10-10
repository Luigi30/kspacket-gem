	SECTION CODE

	public	FileIsMissing

	include	include/GEMDOS.I
	include	include/GEMMACRO.I
	include	include/STMACROS.I

FileIsMissing:
	move.l	a0, a5 ;save this for later

	;allocate a string buffer and place it in a local stack frame
	LINK	a6, #-4

	PUSHL	#256
	GEMDOS	m_alloc, 6
	move.l	d0, a4

	;concat a bunch of strings to make the error message
	move.b	#0, (sp)
	lea		(sp), a0
	lea		formAlertIcon1, a1
	JSR		strcat

	subq	#1, a0 ;overwrite the null
	move.b	#'[', (a0)+
	move.b	#0, (a0)+

	lea		(sp), a0
	lea		errorFileMissing, a1
	JSR		strcat

	lea		(sp), a0
	move.l	a5, a1
	JSR		strcat

	subq	#1, a0 ;overwrite the null
	move.b	#']', (a0)+
	move.b	#0, (a0)+

	lea		(sp), a0
	lea		formAlertButtonExit, a1
	JSR		strcat

	form_alert #1, sp

	PUSHL	(sp)
	GEMDOS	m_free, 6

	UNLK	a6
	JMP		GEMExit
	
******************************

	SECTION DATA
errorFileMissing	dc.b	"Could not load ",0
