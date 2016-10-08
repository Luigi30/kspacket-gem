	SECTION CODE

	public	FileIsMissing

	include	include/GEMMACRO.I

FileIsMissing:
	move.l	a0, a6
	move.b	#0, StringBuilding
	lea		StringBuilding, a0
	lea		formAlertIcon1, a1
	JSR		strcat

	subq	#1, a0 ;overwrite the null
	move.b	#'[', (a0)+
	move.b	#0, (a0)+

	lea		StringBuilding, a0
	lea		errorFileMissing, a1
	JSR		strcat

	lea		StringBuilding, a0
	move.l	a6, a1
	JSR		strcat

	subq	#1, a0 ;overwrite the null
	move.b	#']', (a0)+
	move.b	#0, (a0)+

	lea		StringBuilding, a0
	lea		formAlertButtonExit, a1
	JSR		strcat

	form_alert #1, #StringBuilding

	JMP		GEMExit
	
******************************

	SECTION DATA
errorFileMissing	dc.b	"Could not load ",0
