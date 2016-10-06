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
	xdef	EventMulti
	xdef	OpenWindows
	xdef	HandleKeypress
	xdef	RS232ReceiveException
	xdef 	GotMenuSelectedEvent

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
	include include/BIOS.I
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
	
HookRS232ReceiveVector:
	move.l	$130, OldRS232Vector
	move.l	#RS232ReceiveException, $130 ;ST-MFP-12
	RTS

UnhookRS232ReceiveVector:
	move.l	OldRS232Vector, $130
	RTS

RS232ReceiveException:
	;per http://info-coach.fr/atari/documents/_mydoc/Hitchhikers-Guide-V1.1.pdf
	;Calling the BIOS from an Interrupt Handler - we need to set some stuff up
savptr	equ	$04A2
sav_amt equ 46
	
	;set up a trap environment
	sub.l	#sav_amt, savptr

	PUSHW	#1 ;aux:
	PUSHW	#bconin
	trap	#13
	addq.l	#4,sp

	move.w	d0, SerialBuffer

	;restore old environment
	add.l	#sav_amt, savptr
	RTE

	even
_main:
	JMP START

START:
	;hook the RS-232 receive vector
	;PEA 	HookRS232ReceiveVector
	;PUSHW 	#supexec
	;trap 	#14 ;XBIOS call
	;addq.l	#6,sp

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

	graf_mouse #0 ;reset mouse to an arrow

.mainWindow
	JSR		CreateMainWindow

.surfaceMapWindow:
	JSR		CreateSurfaceMapWindow

OpenWindows:
	wind_open	handle_main_window, #20, #40, #600, #300

********************************************************
EventLoop:
	AESClearIntIn
	AESClearAddrIn

	;delete the last event
	move.l	#0, EventBuffer
	move.l	#0, EventBuffer+4
	move.l	#0, EventBuffer+8
	move.l	#0, EventBuffer+12

	;Wait for keyboard events, AES messages, or the timer.
EventMulti:
	move.w  #$0031, int_in+0 ;ev_mflags
	move.w	#0, int_in+2 	;ev_mbclicks
	move.w	#0, int_in+4 	;ev_mbmask
	move.w	#0, int_in+6 	;ev_mbstate
	move.w	#0, int_in+8 	;ev_mm1flags
	move.w	#0, int_in+10 	;ev_mm1x
	move.w	#0, int_in+12 	;ev_mm1y
	move.w	#0, int_in+14 	;ev_mm1width
	move.w	#0, int_in+16 	;ev_mm1height
	move.w	#0, int_in+18 	;ev_mm2flags
	move.w	#0, int_in+20 	;ev_mm2x
	move.w	#0, int_in+22 	;ev_mm2y
	move.w	#0, int_in+24 	;ev_mm2width
	move.w	#0, int_in+26 	;ev_mm2height
	move.w  #0, int_in+28 	;ev_mtlocount
	move.w	#0, int_in+30 	;ev_mthicount

	move.l	#EventBuffer, addr_in+0 ;ev_mmgpbuff

	evnt_multi  #$0031

	;Stuff we want to do after every event.
PostEventRoutine:
	JSR		CheckSerialBuffer

	;We got an event! What kind is it?
CheckEventType:
	;window manager event?
	cmp.w	#WM_REDRAW, EventBuffer
	beq		GotRedrawEvent

	cmp.w	#WM_MOVED, EventBuffer
	beq		GotMovedEvent

	cmp.w	#WM_CLOSED, EventBuffer
	beq		GEMExit

	cmp.w	#WM_TOPPED, EventBuffer
	beq		GotToppedEvent

	;menu event?
	cmp.w	#MN_SELECTED, EventBuffer
	beq		GotMenuSelectedEvent

	;keyboard event?
	move.w	int_out+10, d0
	cmp.w	#0, d0
	bne		HandleKeypress

	;Uh-oh, we don't know how to handle this event.
	jmp		UnhandledEventType

	JMP		EventLoop

*************************************
NoEventOccurred:
	JMP		EventLoop

*************************************
HandleKeypress:
	;open and close windows based on button presses.
	;scancode is in the high nybble, ASCII is in the low nybble.
	cmp.w	#$3B00, d0 ;F1
	beq		.showMainWindow
	
	cmp.w	#$3C00, d0 ;F2
	beq		.showSurfaceMapWindow

	JMP		EventLoop

.showMainWindow:
	cmp.b		#1, mainWindowIsOpen
	beq			.done ;don't re-open the same window
	wind_close	handle_surface_map_window
	wind_open	handle_main_window, #20, #40, #600, #300

	move.b		#1, mainWindowIsOpen
	move.b		#0, surfaceMapWindowIsOpen
	JMP		.done

.showSurfaceMapWindow:
	cmp.b		#1, surfaceMapWindowIsOpen
	beq			.done ;don't re-open the same window
	wind_close	handle_main_window
	wind_open	handle_surface_map_window, #60, #80, #400, #300

	move.b		#1, surfaceMapWindowIsOpen
	move.b		#0, mainWindowIsOpen
	JMP		.done

.done:
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
	;quit button?
	cmp.w	#16, EventBuffer+8
	beq		GEMExit

	cmp.w	#7, EventBuffer+8
	beq		ShowAboutBox

	;fell through all the checks

.done:
	JMP		EventLoop

*************************************
GEMExit:
	;AESClearIntIn
	;AESClearAddrIn
	;ShowAlert #msgImGay

	;reset the original RS-232 vector
	PEA 	UnhookRS232ReceiveVector
	PUSHW 	#supexec
	trap 	#14 ;XBIOS call
	addq.l	#6,sp

.mainwindow:
	cmp.b	#0, mainWindowIsOpen
	beq		.surfacemapwindow

	wind_close	handle_main_window
	wind_delete	handle_main_window

.surfacemapwindow:
	cmp.b	#0, surfaceMapWindowIsOpen
	beq		.windowsAreClosed
	
	wind_close	handle_surface_map_window
	wind_delete	handle_surface_map_window

.windowsAreClosed:
	appl_exit
	GEMDOS	0, 2 ;pterm0

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
ShowAboutBox:
	form_alert  #1, #msgAboutBox
	JMP			EventLoop

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
CheckSerialBuffer: ;is there data waiting?
	B_Constat	dev_aux
	cmp.w		#0, d0
	beq			.done ;no

.done:
	RTS

*************************************
;Included functions
	include include/LINEHORZ.I
	include include/VIDEO.I
*************************************

	SECTION DATA
OldRS232Vector	dc.l	0

;Messages
	even
msgAnyKey		dc.b	"Press any key to return to GEM.",0
msgAlertBox		dc.b	"[1][Everything is fucked!|Here's a GEM alert.][EXIT]"
msgAboutBox		dc.b	"[0][   Kerbal Mission Control  |   by Luigi Thirty, 2016| |aut viam inveniam aut faciam  ][Close]"
msgImGay		dc.b	"[2][I'm gay.][I, too, am gay.]"
msgRsrcMissing	dc.b	"[1][Could not load POLYGON.RSC.][EXIT]"

*************************************

	SECTION BSS
				ds.l     256 ; 1KB stack
stack    		ds.l     1
