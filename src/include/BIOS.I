* Equates for accessing the Atari BIOS
* (c) HiSoft 1990
getmpb		equ	0
bconstat	equ	1
bconin		equ	2
bconout		equ	3
rwabs		equ	4
setexc		equ	5
tickcal		equ	6
getbpb		equ	7
bcostat		equ	8
mediach		equ	9
drvmap		equ	10
kbshift		equ	11

dev_prn		equ 0
dev_aux		equ 1
dev_con		equ 2
dev_midi	equ 3
dev_kbd		equ 4
dev_screen	equ	5

************************************
B_Constat	MACRO
	move.w	#\1, -(sp)
	move.w	#bconstat, -(sp)
	trap	#13
	addq.l	#4, sp
			ENDM
************************************
B_Conin		MACRO
	move.w	#\1, -(sp)
	move.w	#bconin, -(sp)
	trap	#13
	addq.l	#4, sp
			ENDM
************************************
