	opt x+
	opt d

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
	xdef	ProcessWindowMoved
	xdef	UnhandledEventType
	xdef	CopyWindowCoords
	xdef	DrawLabels
	xdef	GEMExit
	xdef	EventBuffer
	xdef	EventLoop
	xdef 	GotToppedEvent
	xdef	LoadFontInfo

	xdef 	aes_intin
	xdef 	WF_NAME
	xdef	WF_INFO

	xdef 	ResourceMissing

	xref 	application_id
	xref 	gr_hhbox

	xref	handle_main_window
	xref	handle_surface_map_window

*************************************

;resource info
	include	POLYGON.RSH
*************************************

;included macros
	include include/GEMDOS.I
	include include/XBIOS.I
	include include/STMACROS.I
	include	include/GEMMACRO.I
*************************************

;ShowAlert MACRO
;	move.w	#form_alert, d0
;	move.w	#1, int_in
;	move.l	\1, addr_in
;	JSR		CALL_AES
;	ENDM
*************************************

M_BresenhamLine	MACRO
	move.w	\1, bresenham_line_x1
	move.w	\2, bresenham_line_x2
	move.w	\3, bresenham_line_y1
	move.w	\4, bresenham_line_y2
	jsr		BresenhamLine
				ENDM
*************************************

M_SwapEndianness	MACRO
				    ror.w   #8, \1
				    swap    \1
				    ror.w   #8, \1
					ENDM
*************************************
	
	even
_main:
	JMP START

START:
	jsr	PopulateTestData
	jsr	GetPhysicalBase
	jsr	GetLogicalBase

	AESClearIntIn
	AESClearAddrIn
	VDIClearIntIn
	VDIClearPtsIn

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

LoadFontInfo:
	lea			intout+2, a0
	vqt_name	#0
	vqt_name	#1

	graf_mouse #0 ;reset mouse to an arrow

.mainWindow
	JSR		CreateMainWindow

.surfaceMapWindow:
	JSR		CreateSurfaceMapWindow

EventLoop:
	evnt_mesag	#EventBuffer

CheckEventType:
	cmp.w	#WM_REDRAW, EventBuffer
	beq		GotRedrawEvent

	cmp.w	#WM_MOVED, EventBuffer
	beq		GotMovedEvent

	cmp.w	#WM_CLOSED, EventBuffer
	beq		GEMExit

	cmp.w	#WM_TOPPED, EventBuffer
	beq		GotToppedEvent

	cmp.w	#MN_SELECTED, EventBuffer
	beq		GotMenuSelectedEvent

	jmp		UnhandledEventType

	JMP		EventLoop

*************************************
GotRedrawEvent:
	move.w	handle_main_window, d0
	cmp.w	EventBuffer+6, d0
	beq		.isMainWindow

	move.w	handle_surface_map_window, d0
	cmp.w	EventBuffer+6, d0
	beq		.isSurfaceMapWindow

	;??? not a valid window handle
	JMP		EventLoop	

.isMainWindow
	JSR		RedrawMainWindow
	JMP		EventLoop

.isSurfaceMapWindow:
	JSR		RedrawSurfaceMapWindow
	JMP		EventLoop

*************************************
GotToppedEvent:
	move.w	handle_main_window, d0
	cmp.w	EventBuffer+6, d0
	beq		.isMainWindow

	move.w	handle_surface_map_window, d0
	cmp.w	EventBuffer+6, d0
	beq		.isSurfaceMapWindow

	;??? not a valid window handle
	JMP		EventLoop	

.isMainWindow
	wind_set handle_main_window, #WF_TOP
	JMP		EventLoop

.isSurfaceMapWindow:
	wind_set handle_surface_map_window, #WF_TOP
	JMP		EventLoop

*************************************
GotMovedEvent:
	move.w	handle_main_window, d0
	cmp.w	EventBuffer+6, d0
	beq		.isMainWindow

	move.w	handle_surface_map_window, d0
	cmp.w	EventBuffer+6, d0
	beq		.isSurfaceMapWindow

	;??? not a valid window handle
	JMP		EventLoop	

.isMainWindow
	JSR		MoveMainWindow
	JMP		EventLoop

.isSurfaceMapWindow:
	JSR		MoveSurfaceMapWindow
	JMP		EventLoop	

*************************************
GotMenuSelectedEvent:
	move.w	handle_main_window, d0
	cmp.w	EventBuffer+6, d0
	beq		.isMainWindow

	move.w	handle_surface_map_window, d0
	cmp.w	EventBuffer+6, d0
	beq		.isSurfaceMapWindow

	;??? not a valid window handle
	JMP		EventLoop	

.isMainWindow
	JSR		MenuSelectedMainWindow
	JMP		EventLoop

.isSurfaceMapWindow:
	JSR		MenuSelectedSurfaceMapWindow
	JMP		EventLoop

*************************************
GEMExit:
	AESClearIntIn
	AESClearAddrIn
	;ShowAlert #msgImGay

	wind_close	handle_main_window
	wind_close	handle_surface_map_window
	wind_delete	handle_main_window
	wind_delete	handle_surface_map_window

	appl_exit

End:
	GEMDOS	0, 0 ;pterm0

******************************
ResourceMissing:
	AESClearIntIn
	AESClearAddrIn
	form_alert  #1, #msgRsrcMissing
	JMP			GEMExit

******************************
UnhandledEventType:
	;allow for a breakpoint
	move.w	EventBuffer, d0
	JMP		EventLoop

******************************
vdi:
    movem.l a0-a7/d0-d7,-(sp)       ; Save registers.
    move.l  #vdi_params,d1          ; Load addr of vpb.
    move.w  #115,d0		            ; Load VDI opcode.
    trap    #2                      ; Call VDI.
    movem.l (sp)+,a0-a7/d0-d7       ; Restore registers.
    rts

*************************************
DrawLabels:
	;d0 = character height
	;d1 = window top left X
	;d2 = window top left Y

	;move these so they don't get eaten by v_gtext
	move.w		d0, d4 ;height
	move.w		d1, d5 ;top left X
	move.w		d2, d6 ;top left Y

	move.w		d6, d7

	add.w		#COLUMN_1, d5

	add.w		d4, d6
	v_gtext		d5, d6, #lbl_G
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_AP
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_PE
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_SemiMajorAxis
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_SemiMinorAxis
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_e
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_VVI
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_inc
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_TAp
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_TPe
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_TrueAnomaly
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_period

	;Fuel quantities
	move.w		#COLUMN_2, d5
	move.w		d7, d6

	add.w		d4, d6
	v_gtext		d5, d6, #lbl_SolidFuel
	add.w		d4, d6	
	v_gtext		d5, d6, #lbl_LiquidFuel
	add.w		d4, d6	
	v_gtext		d5, d6, #lbl_Oxidizer
	add.w		d4, d6	
	v_gtext		d5, d6, #lbl_ECharge
	add.w		d4, d6	

	;Surface info
	move.w		#COLUMN_3, d5
	move.w		d7, d6

	add.w		d4, d6
	v_gtext		d5, d6, #lbl_Pitch
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_Roll
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_Heading
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_Lat
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_Lon
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_RAlt
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_Density
	add.w		d4, d6
	v_gtext		d5, d6, #lbl_Vsurf

	RTS

*************************************

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

*************************************
;Included functions
	include include/LINEHORZ.I
	include include/VIDEO.I
*************************************

	SECTION DATA
;Messages
msgAnyKey		dc.b	"Press any key to return to GEM.",0
msgAlertBox		dc.b	"[1][Everything is fucked!|Here's a GEM alert.][EXIT]"
msgImGay		dc.b	"[2][I'm gay.][I, too, am gay.]"
msgRsrcMissing	dc.b	"[1][Could not load POLYGON.RSC.][EXIT]"

font6x6			dc.b	"6x6 system font"
font8x8			dc.b	"8x8 system font"
*************************************

	SECTION BSS
				ds.l     256 ; 1KB stack
stack    		ds.l     1
