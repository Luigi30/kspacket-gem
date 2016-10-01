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
	xdef	ProcessWindowMoved
	xdef	UnhandledEventType
	xdef	CopyWindowCoords
	xdef	DrawLabels
	xdef	HandleMainWindowMenuClick
*************************************

;resource info
	include	POLYGON.RSH
*************************************

;included macros
	include include/GEMDOS.I
	include include/XBIOS.I
	include include/STMACROS.I
	include	include/GEMMACRO.I
	include include/KSPACKET.I
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

M_FloatToString		MACRO
					move.l	value_\1, d0
					lea		string_\1, a0
					JSR		FloatToString
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

	graf_mouse #0 ;reset mouse to an arrow

MakeMainWindow:
	AESClearIntIn
	AESClearAddrIn
	VDIClearIntIn
	VDIClearPtsIn

	rsrc_load	#mainWindowResource
	cmp.w		#0, aes_intout
	beq			ResourceMissing ;couldn't load the resource file

	AESClearIntIn
	AESClearAddrIn
	VDIClearIntIn
	VDIClearPtsIn

	rsrc_gaddr	#0, #0 ;main
	cmp.w		#0, aes_intout
	beq			ResourceMissing ;couldn't load the resource file

	move.l		aes_addrout, mainWindowMenuAddress
	menu_bar	mainWindowMenuAddress, #1

	wind_create #$001B, #20, #40, #600, #300
	move.w		d0, handle_main_window

	move.l		#msgKSP, aes_intin+4
	wind_set	handle_main_window, #WF_NAME
	move.l		#msgInfoBar, aes_intin+4
	wind_set	handle_main_window, #WF_INFO

	AESClearIntIn
	AESClearAddrIn

	wind_open	handle_main_window, #20, #40, #600, #300

EventLoop:
	evnt_mesag	#EventBuffer

CheckEventType:
	cmp.w	#WM_REDRAW, EventBuffer
	beq		RedrawMainWindow

	cmp.w	#WM_MOVED, EventBuffer
	beq		ProcessWindowMoved

	cmp.w	#WM_CLOSED, EventBuffer
	beq		GEMExit

	cmp.w	#MN_SELECTED, EventBuffer
	beq		HandleMainWindowMenuClick

	jmp		UnhandledEventType

	JMP		EventLoop

*************************************
GEMExit:
	AESClearIntIn
	AESClearAddrIn
	;ShowAlert #msgImGay
	move.w	#appl_exit, d0
	jsr		CALL_AES

End:
	GEMDOS	0, 0 ;pterm0

******************************
HandleMainWindowMenuClick:
	;What button was clicked?
	move.w	EventBuffer+6, d0
	move.w	EventBuffer+8, d1

	cmp.w	#MENU_BUTTON_KERBAL_MISSION_CONTROL, d1
	beq		HandleButtonMissionControl

	cmp.w	#MENU_BUTTON_QUIT, d1
	beq		GEMExit

	JMP		EventLoop
*************************************
HandleButtonMissionControl:
	AESClearIntIn
	AESClearAddrIn
	form_alert	#1, #msgAbout
	JMP		EventLoop

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
Wind_Set_FourArgs	MACRO
	move.w		\1, aes_intin+4
	move.w		\2, aes_intin+6
	move.w		\3, aes_intin+8
	move.w		\4, aes_intin+10
	ENDM

ProcessWindowMoved:
	;get the window's handle. we only have one window so...
	move.w		EventBuffer+6, d0
	cmp.w		handle_main_window, d0
	bne			.notOurWindow

	;Move the window.
	Wind_Set_FourArgs	EventBuffer+8, EventBuffer+10, EventBuffer+12, EventBuffer+14
	wind_set	handle_main_window, #WF_CURRXYWH

	jmp			EventLoop

.notOurWindow:
	form_alert 	#1, #msgAlertBox
	trap		#0 ;crash

******************************
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

CopyWindowCoords:
	move.w		temp_coord1_x, ptsin
	move.w		temp_coord1_y, ptsin+2
	move.w		temp_coord2_x, ptsin+4
	move.w		temp_coord2_y, ptsin+6
	move.w		temp_coord3_x, ptsin+8
	move.w		temp_coord3_y, ptsin+10
	move.w		temp_coord4_x, ptsin+12
	move.w		temp_coord4_y, ptsin+14

	v_fillarea	#4

	AESClearIntIn
	AESClearAddrIn
	VDIClearIntIn
	VDIClearPtsIn

	;Redraw the KSP labels
	move.w		gr_hhchar, d0
	move.w		main_window_work_x, d1
	move.w		main_window_work_y, d2
	JSR			DrawLabels

	move.l		#msgProcessing, aes_intin+4
	wind_set	handle_main_window, #WF_INFO
	JSR			ProcessRawValues

	move.l		#msgInfoBar, aes_intin+4
	wind_set	handle_main_window, #WF_INFO

	;Redraw the KSP values
	move.w		gr_hhchar, d0
	move.w		main_window_work_x, d1
	move.w		main_window_work_y, d2
	JSR			DrawValues

	;add.w		d1, temp_coord1_y
	;v_gtext	temp_coord1_x, temp_coord1_y, #lbl_AP

	wind_update	#0 ;end update

	graf_mouse	#257 ;mouse on
	JMP EventLoop
*************************************

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
ProcessRawValues:

	;This takes approximately 10 years on an 8MHz 68000
	M_FloatToString AP
	M_FloatToString PE			
	M_FloatToString SemiMajorAxis	
	M_FloatToString SemiMinorAxis	
	M_FloatToString VVI			
	M_FloatToString e				
	M_FloatToString inc			
	M_FloatToString G				
	M_FloatToString TAp			
	M_FloatToString TPe			
	M_FloatToString TrueAnomaly	
	M_FloatToString Density		
	M_FloatToString period		
	M_FloatToString RAlt			
	M_FloatToString Alt			
	M_FloatToString Vsurf			
	M_FloatToString Lat			
	M_FloatToString Lon			

;Fuel
	M_FloatToString LiquidFuelTot	
	M_FloatToString LiquidFuel	
	M_FloatToString OxidizerTot	
	M_FloatToString Oxidizer		
	M_FloatToString EChargeTot	
	M_FloatToString ECharge		
	M_FloatToString MonoPropTot	
	M_FloatToString MonoProp		
	M_FloatToString IntakeAirTot	
	M_FloatToString IntakeAir		
	M_FloatToString SolidFuelTot	
	M_FloatToString SolidFuel		
	M_FloatToString XenonGasTot	
	M_FloatToString XenonGas		
	M_FloatToString LiquidFuelTotS	
	M_FloatToString LiquidFuelS	
	M_FloatToString OxidizerTotS	
	M_FloatToString OxidizerS		

	M_FloatToString MissionTime	
	M_FloatToString deltaTime		
	M_FloatToString VOrbit		
	M_FloatToString MNTime		
	M_FloatToString MNDeltaV		
	M_FloatToString Pitch			
	M_FloatToString Roll			
	M_FloatToString Heading		
	;M_FloatToString ActionGroups ;word
	;M_FloatToString SOINumber ;byte
	;M_FloatToString MaxOverheat ;byte
	M_FloatToString MachNumber
	M_FloatToString IAS
	;M_FloatToString CurrentStage ;byte
	;M_FloatToString TotalStage ;byte

	RTS

*************************************
DrawValues:
	;d0 = character height
	;d1 = window top left X
	;d2 = window top left Y

	;move these so they don't get eaten by v_gtext
	move.w		d0, d4 ;height
	move.w		d1, d5 ;top left X
	move.w		d2, d6 ;top left Y
	move.w		d6, d7

	add.w		#VALUE_COLUMN_1, d5

	add.w		d4, d6
	v_gtext		d5, d6, #string_G

	add.w		d4, d6
	v_gtext		d5, d6, #string_AP

	add.w		d4, d6
	v_gtext		d5, d6, #string_PE

	add.w		d4, d6
	v_gtext		d5, d6, #string_SemiMajorAxis

	add.w		d4, d6
	v_gtext		d5, d6, #string_SemiMinorAxis

	add.w		d4, d6
	v_gtext		d5, d6, #string_e

	add.w		d4, d6
	v_gtext		d5, d6, #string_VVI

	add.w		d4, d6
	v_gtext		d5, d6, #string_inc

	add.w		d4, d6
	v_gtext		d5, d6, #string_TAp

	add.w		d4, d6
	v_gtext		d5, d6, #string_TPe

	add.w		d4, d6
	v_gtext		d5, d6, #string_TrueAnomaly

	add.w		d4, d6
	v_gtext		d5, d6, #string_period

	;Fuel quantities
	move.w		#VALUE_COLUMN_2, d5
	move.w		d7, d6

	add.w		d4, d6
	v_gtext		d5, d6, #string_SolidFuel

	add.w		d4, d6	
	v_gtext		d5, d6, #string_LiquidFuel

	add.w		d4, d6	
	v_gtext		d5, d6, #string_Oxidizer

	add.w		d4, d6	
	v_gtext		d5, d6, #string_ECharge

	;Surface info
	move.w		#VALUE_COLUMN_3, d5
	move.w		d7, d6

	add.w		d4, d6
	v_gtext		d5, d6, #string_Pitch

	add.w		d4, d6
	v_gtext		d5, d6, #string_Roll

	add.w		d4, d6
	v_gtext		d5, d6, #string_Heading

	add.w		d4, d6
	v_gtext		d5, d6, #string_Lat

	add.w		d4, d6
	v_gtext		d5, d6, #string_Lon

	add.w		d4, d6
	v_gtext		d5, d6, #string_RAlt

	add.w		d4, d6
	v_gtext		d5, d6, #string_Density

	add.w		d4, d6
	v_gtext		d5, d6, #string_Vsurf

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
*************************************
;Included functions
	include include/SINCOS.I
	include include/LINEHORZ.I
	include include/VIDEO.I
	include	include/AESLIB.S
	include include/VDILIB.S
	include	include/FLOAT.I
*************************************

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

;layout
COLUMN_1	equ	0
COLUMN_2	equ	200
COLUMN_3	equ 400

VALUE_COLUMN_1	equ	80
VALUE_COLUMN_2	equ	280
VALUE_COLUMN_3	equ 480

;Pointers
GFX_BASE			dc.l	0
GFX_LOGICAL_BASE	dc.l	0

;Buffers
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
msgImGay		dc.b	"[2][I'm gay.][I, too, am gay.]"
msgRsrcMissing	dc.b	"[1][Could not load POLYGON.RSC.][EXIT]"
msgAbout		dc.b	"[2][Kerbal Mission Control||By Luigi Thirty, 2016][Okay]"
msgKSP			dc.b	"Kerbal Space Packet",0
msgInfoBar		dc.b	" Kerbal Space Packet",0
msgProcessing	dc.b	" Processing packet data...",0

mainWindowResource 		dc.b	"POLYGON.RSC",0
mainWindowMenuAddress	dc.l	0
*************************************

	SECTION BSS
				ds.l     256 ; 1KB stack
stack    		ds.l     1
