	opt x+

;Symbol definitions - symbols have to be here to show up in the debugger
	SECTION CODE

	xdef	START
	xdef	ShowFileSelector
	xdef	WaitForKeypress
	xdef	VDIInit
	xdef	MakeMainWindow
	xdef	CheckEventType
	xdef	RedrawMainWindow
	xdef	DoVsClip
	xdef	DoWindGet

;included macros
	include include/GEMDOS.I
	include include/XBIOS.I
	include include/STMACROS.I
	include	include/GEMMACRO.I
	include include/KSPACKET.I

M_BresenhamLine	MACRO
	move.w	\1, bresenham_line_x1
	move.w	\2, bresenham_line_x2
	move.w	\3, bresenham_line_y1
	move.w	\4, bresenham_line_y2
	jsr		BresenhamLine
				ENDM

M_KSPacketLabel MACRO
	;\1 = X cell, \2 = Y cell, \3 = string pointer
	move.w	gr_hhchar, d0
	clr.w	d1
	move.w	\2, d2
.hloop\@:
	add.w	d0, d1
	dbra	d2, .hloop\@

	move.w	gr_hwchar, d0
	clr.w	d3
	move.w	\1, d2
.wloop\@:
	add.w	d0, d3
	dbra	d2, .wloop\@

	v_gtext d3, d1, #\3
				ENDM
	
	nop ;align
_main:
	JMP START

START:
	jsr	GetPhysicalBase
	jsr	GetLogicalBase

AESInit:
	appl_init
	move.w	d0, application_id

VDIInit:
	graf_handle
	;Grab the data from graf_handle
	move.w	aes_intout, gr_handle ;defined in VDILIB.S
	move.w	aes_intout+2, gr_hwchar
	move.w	aes_intout+4, gr_hhchar
	move.w	aes_intout+6, gr_hwbox
	move.w	aes_intout+8, gr_hhbox
	
	;Default parameters
	move.w	#1, vdi_intin+0
	move.w	#1, vdi_intin+2
	move.w	#1, vdi_intin+4
	move.w	#1, vdi_intin+6
	move.w	#1, vdi_intin+8
	move.w	#1, vdi_intin+10
	move.w	#1, vdi_intin+12
	move.w	#1, vdi_intin+14
	move.w	#1, vdi_intin+16
	move.w	#1, vdi_intin+18
	move.w	#2, vdi_intin+20

	;Open a virtual workstation
	v_opnvwk ;it's cleared automatically

	graf_mouse #0 ;reset mouse to an arrow

MakeMainWindow:
	wind_create #$001B, #50, #50, #400, #300
	move.w		d0, handle_main_window

	move.l		#msgKSP, aes_intin+4
	wind_set	handle_main_window, #WF_NAME
	wind_set	handle_main_window, #WF_INFO

	wind_open	handle_main_window, #50, #50, #400, #300

EventLoop:
	evnt_mesag	#EventBuffer

CheckEventType:
	cmp.w	#WM_REDRAW, EventBuffer
	beq		RedrawMainWindow

	cmp.w	#WM_CLOSED, EventBuffer
	beq		GEMExit

	JMP		EventLoop

WaitForKeypress:
	;Drawing some text
	;move.w	gr_hhchar, d0
	;v_gtext #0, d0, #msgAnyKey

	;Wait for keypress...
	;GEMDOS	c_conin

GEMExit:
	move.w	#appl_exit, d0
	jsr		CALL_AES

End:
	GEMDOS	0, 0 ;pterm0

RedrawMainWindow:
	graf_mouse	#256 ;mouse off

	wind_update	#1 ;begin update

DoWindGet:
	wind_get	handle_main_window, #WF_WORKXYWH
	move.w		aes_intout+2, main_window_work_x
	move.w		aes_intout+4, main_window_work_y
	move.w		aes_intout+6, main_window_work_w
	move.w		aes_intout+8, main_window_work_h

DoVsClip:
	;wind_get returns X,Y,W,H. vs_clip wants X,Y and X,Y of the opposite corner
	move.w		main_window_work_x, temp_coord1_x
	move.w		main_window_work_y, temp_coord1_y

	move.w		main_window_work_x, temp_coord2_x
	move.w		main_window_work_y, temp_coord2_y

	move.w		main_window_work_w, d0
	add.w		d0, temp_coord2_x
	move.w		main_window_work_h, d0
	add.w		d0, temp_coord2_y

	;clip to the window's work area
	vs_clip		#1, temp_coord1_x, temp_coord1_y, temp_coord2_x, temp_coord2_y
	vsf_color	#0 ;white

	;temp_coord1 = top left
	;temp_coord2 = top right
	;temp_coord3 = bottom left
	;temp_coord4 = bottom right
	JSR			FillTempCoordsWithMainWindowCorners

	move.w		temp_coord1_x, ptsin
	move.w		temp_coord1_y, ptsin+2
	move.w		temp_coord2_x, ptsin+4
	move.w		temp_coord2_y, ptsin+6
	move.w		temp_coord3_x, ptsin+8
	move.w		temp_coord3_y, ptsin+10
	move.w		temp_coord4_x, ptsin+12
	move.w		temp_coord4_y, ptsin+14

	v_fillarea	#4

	;v_gtext #0, #100, #msgAnyKey

	wind_update	#0 ;end update

	graf_mouse	#257 ;mouse on
	JMP EventLoop

vdi:
    movem.l a0-a7/d0-d7,-(sp)       ; Save registers.
    move.l  #vdi_params,d1          ; Load addr of vpb.
    move.w  #115,d0		            ; Load VDI opcode.
    trap    #2                      ; Call VDI.
    movem.l (sp)+,a0-a7/d0-d7       ; Restore registers.
    rts

DrawLabels:
	M_KSPacketLabel #0, #3, lbl_AP				;dc.b	"Ap      : ",0
	M_KSPacketLabel #0, #4, lbl_PE				;dc.b	"Pe      : ",0
	M_KSPacketLabel #0, #5, lbl_SemiMajorAxis	;dc.b	"SMajAxis: ",0
	M_KSPacketLabel #0, #6, lbl_SemiMinorAxis	;dc.b	"SMinAxis: ",0
	M_KSPacketLabel #0, #7, lbl_VVI				;dc.b	"Vert Vel: ",0
	M_KSPacketLabel #0, #8, lbl_e				;dc.b	"Eccentrc: ",0
	M_KSPacketLabel #0, #9, lbl_inc				;dc.b	"O Inclin: ",0
	M_KSPacketLabel #0, #10, lbl_G				;dc.b	"Gravity : ",0
	M_KSPacketLabel #0, #11, lbl_TAp			;dc.b	"TimeToAp: ",0
	M_KSPacketLabel #0, #12, lbl_TPe			;dc.b	"TimeToPe: ",0
	M_KSPacketLabel #0, #13, lbl_TrueAnomaly	;dc.b	"TrueAnom: ",0
	M_KSPacketLabel #0, #14, lbl_Density		;dc.b	"Atm Dens: ",0
	M_KSPacketLabel #0, #15, lbl_period			;dc.b	"ObtPriod: ",0
	M_KSPacketLabel #0, #16, lbl_RAlt			;dc.b	"RadarAlt: ",0
	M_KSPacketLabel #0, #17, lbl_Alt			;dc.b	"Altitude: ",0
	M_KSPacketLabel #0, #18, lbl_Vsurf			;dc.b	"SfcVeloc: ",0
	M_KSPacketLabel #0, #19, lbl_Lat			;dc.b	"Sfc Lat : ",0
	M_KSPacketLabel #0, #10, lbl_Lon			;dc.b	"Sfc Long: ",0

ShowAlert:
	move.w	#form_alert, d0
	move.w	#1, int_in
	move.l	#msgAlertBox, addr_in
	JSR		CALL_AES

ShowFileSelector:
	;Construct the pathname.

.GetCurrentDrive:
	GEMDOS	d_getdrv
	add		#'A', d0
	move.b	d0, PathName
	move.b	#':', PathName+1

.GetFullPath:
	PUSHW	#0
	PUSHL	#PathName+2
	GEMDOS	d_getpath, 8

	;find the end of the string and append \*.* to the end
	move.l	#PathName+2, a0
.loop:
	cmp.b	#0, (a0)+
	bne		.loop
	sub		#1, a0 ;oops, we went one past
	;a0 is now the end of PathName
	move.l	a0, a5 ;save a0
	move.l	#'\\*.*',(a0)+

	fsel_input #PathName, #FileName

	;Copy the filename over the end of the pathname.
	move.l	#FileName, a0
	add		#1, a5
.filenameLoop:
	cmp.b	#0, (a0)
	beq		.filenameDone
	move.b	(a0)+,(a5)+
	jmp		.filenameLoop

.filenameDone:
	PUSHL	#PathName
	GEMDOS	c_conws, 8

	RTS

FillTempCoordsWithMainWindowCorners:
	;main_window_work_x and y must be filled in for this to work

	move.w		main_window_work_x, temp_coord1_x
	move.w		main_window_work_y, temp_coord1_y
	
	move.w		main_window_work_x, temp_coord2_x
	move.w		main_window_work_y,	temp_coord2_y
	move.w		main_window_work_w, d0
	add.w		d0, temp_coord2_x

	move.w		main_window_work_x, temp_coord3_x
	move.w		main_window_work_y,	temp_coord3_y
	move.w		main_window_work_w, d0
	add.w		d0, temp_coord3_x
	move.w		main_window_work_h, d0
	add.w		d0, temp_coord3_y

	move.w		main_window_work_x, temp_coord4_x
	move.w		main_window_work_y,	temp_coord4_y
	move.w		main_window_work_h, d0
	add.w		d0, temp_coord4_y

	RTS

;Included functions
	include include/SINCOS.I
	include include/LINEHORZ.I
	include include/VIDEO.I
	include	include/AESLIB.S
	include include/VDILIB.S

	SECTION DATA
application_id		dc.w	0 ;AES ID

;graf info
gr_handle	dc.w	0
gr_hwchar	dc.w	0 ;Width of a character cell
gr_hhchar	dc.w	0 ;Height of a character cell
gr_hwbox	dc.w	0 ;Width of a box that will enclose a character cell
gr_hhbox	dc.w	0 ;Height of a box that will enclose a character cell

;temp coordinate variables
temp_coord1_x	dc.w	0
temp_coord1_y	dc.w	0
temp_coord2_x	dc.w	0
temp_coord2_y	dc.w	0
temp_coord3_x	dc.w	0
temp_coord3_y	dc.w	0
temp_coord4_x	dc.w	0
temp_coord4_y	dc.w	0

handle_main_window	dc.w	0

;top left coordinates
main_window_work_x	dc.w	0
main_window_work_y	dc.w	0
main_window_work_w	dc.w	0
main_window_work_h	dc.w	0

;Pointers
GFX_BASE			dc.l	0
GFX_LOGICAL_BASE	dc.l	0

;Buffers
FloatBuffer		ds.b	8
ScratchBuffer	ds.b	128
StringBuilding	ds.b	128
EventBuffer		ds.b	16

;String buffers
PathName		ds.b	128
FileName		ds.b	128

;Escape codes
ClearHome		dc.b	$1B,"E",0
PositionCursor	dc.b	$1B,"Y",0
NewLine			dc.b	$0D,$0A,0

;Messages
msgAnyKey		dc.b	"Press any key to return to GEM.",0
msgAlertBox		dc.b	"[1][Everything is fucked!|Here's a GEM alert.][EXIT]"
msgKSP			dc.b	"Kerbal Space Packet",0

	SECTION BSS
				ds.l     256 ; 1KB stack
stack    		ds.l     1
