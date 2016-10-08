	SECTION CODE

	include include/STMACROS.I
	include	include/GEMMACRO.I

	xdef handle_main_window

	xdef HandleMainWindowMenuClick

	xdef CreateMainWindow
	xdef RedrawMainWindow
	xdef MoveMainWindow
	xdef MenuSelectedMainWindow
	xdef ProcessRawValues

	xref EventLoop
	xref FileIsMissing

	xdef GetNextRectangle

;resource info
	include	POLYGON.RSH

******************************
CreateMainWindow:
	AESClearIntIn
	AESClearAddrIn
	VDIClearIntIn
	VDIClearPtsIn

	rsrc_load	#mainWindowResource
	cmp.w		#0, aes_intout
	beq			.resourceMissing ;couldn't load the resource file

	AESClearIntIn
	AESClearAddrIn
	VDIClearIntIn
	VDIClearPtsIn

	rsrc_gaddr	#0, #0 ;main
	cmp.w		#0, aes_intout
	beq			.resourceMissing ;couldn't load the resource file

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

	JMP	UpdateData

.resourceMissing:
	LEA		mainWindowResource, a0
	JMP		FileIsMissing

******************************
UpdateData:
	move.l		#msgProcessing, aes_intin+4
	wind_set	handle_main_window, #WF_INFO
	JSR			ProcessRawValues

	move.l		#msgInfoBar, aes_intin+4
	wind_set	handle_main_window, #WF_INFO

	RTS

******************************
RedrawMainWindow:
	graf_mouse	#256 ;mouse off

	move.w		#0, rectangleIndex

	wind_update	#1 ;begin update

	wind_get	handle_main_window, #WF_WORKXYWH
	move.w		aes_intout+2, main_window_work_x
	move.w		aes_intout+4, main_window_work_y
	move.w		aes_intout+6, main_window_work_w
	move.w		aes_intout+8, main_window_work_h

.getFirstRectangle:
	wind_get	handle_main_window, #WF_FIRSTXYWH
	move.w		aes_intout+2, currentRectangleX
	move.w		aes_intout+4, currentRectangleY
	move.w		aes_intout+6, currentRectangleW
	move.w		aes_intout+8, currentRectangleH

	JSR			RedrawMainWindowArea
	
GetNextRectangle:
	wind_get	handle_main_window, #WF_NEXTXYWH
	move.w		rectangleIndex, d0

	;Is there actually another rectangle on the list?
	cmp.w		#0, aes_intout+6 ;w
	beq			.updateDone
	cmp.w		#0, aes_intout+8 ;h
	beq			.updateDone

	move.w		aes_intout+2, currentRectangleX
	move.w		aes_intout+4, currentRectangleY
	move.w		aes_intout+6, currentRectangleW
	move.w		aes_intout+8, currentRectangleH
	JSR			RedrawMainWindowArea

	addq		#1, rectangleIndex

	JMP			GetNextRectangle	

.updateDone:
	wind_update	#0 ;end update

	graf_mouse	#257 ;mouse on
	
	RTS

*************************************
RedrawMainWindowArea:
	;todo: make this actually efficient

	vst_point	#FONT_8X16
	
DoVsClip:
	;wind_get returns X,Y,W,H. vs_clip wants X,Y and X,Y of the opposite corner
	move.w		currentRectangleX, temp_coord1_x
	move.w		currentRectangleY, temp_coord1_y

	move.w		currentRectangleX, temp_coord2_x
	move.w		currentRectangleY, temp_coord2_y

	move.w		currentRectangleW, d0
	add.w		d0, temp_coord2_x
	move.w		currentRectangleH, d0
	add.w		d0, temp_coord2_y

	sub.w		#1, temp_coord2_x
	sub.w		#1, temp_coord2_y

	;clip to the redrawing rectangle
	vs_clip		#1, temp_coord1_x, temp_coord1_y, temp_coord2_x, temp_coord2_y
	vsf_color	#0 ;white

	;temp_coord1 = top left
	;temp_coord2 = top right
	;temp_coord3 = bottom left
	;temp_coord4 = bottom right
	JSR			FillTempCoordsWithRectangleListCorners

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

	move.b		updateDataFlag, d0
	cmp.b		#1, updateDataFlag
	beq			.redrawValues

	JSR			UpdateData
	move.b		#1, updateDataFlag

.redrawValues:
	;Redraw the KSP values
	move.w		gr_hhchar, d0
	move.w		main_window_work_x, d1
	move.w		main_window_work_y, d2
	JSR			DrawValues

	;add.w		d1, temp_coord1_y
	;v_gtext	temp_coord1_x, temp_coord1_y, #lbl_AP

	RTS

*************************************
Wind_Set_FourArgs	MACRO
	move.w		\1, aes_intin+4
	move.w		\2, aes_intin+6
	move.w		\3, aes_intin+8
	move.w		\4, aes_intin+10
	ENDM

*************************************
HandleMainWindowMenuClick:
	;What button was clicked?
	move.w	EventBuffer+6, d0
	move.w	EventBuffer+8, d1

	cmp.w	#MENU_BUTTON_KERBAL_MISSION_CONTROL, d1
	beq		HandleButtonMissionControl

	cmp.w	#MENU_BUTTON_QUIT, d1
	beq		Quit

	RTS

*************************************
HandleButtonMissionControl:
	AESClearIntIn
	AESClearAddrIn
	form_alert	#1, #msgAbout
	JMP		EventLoop

*************************************
MoveMainWindow:
	;Move the window.
	Wind_Set_FourArgs	EventBuffer+8, EventBuffer+10, EventBuffer+12, EventBuffer+14
	wind_set	handle_main_window, #WF_CURRXYWH

	RTS

*************************************
MenuSelectedMainWindow:
	RTS

*************************************
Quit:
	JMP		GEMExit

*************************************
FillTempCoordsWithRectangleListCorners:
	;main_window_work_x and y must be filled in for this to work

	move.w		currentRectangleX, temp_coord1_x
	move.w		currentRectangleY, temp_coord1_y
	
	move.w		currentRectangleX, temp_coord2_x
	move.w		currentRectangleY, temp_coord2_y
	move.w		currentRectangleW, d0
	add.w		d0, temp_coord2_x

	move.w		currentRectangleX, temp_coord3_x
	move.w		currentRectangleY,	temp_coord3_y
	move.w		currentRectangleW, d0
	add.w		d0, temp_coord3_x
	move.w		currentRectangleH, d0
	add.w		d0, temp_coord3_y

	move.w		currentRectangleX, temp_coord4_x
	move.w		currentRectangleY,	temp_coord4_y
	move.w		currentRectangleH, d0
	add.w		d0, temp_coord4_y

	RTS

DrawNextValue	MACRO
	add.w		d4, d6
	v_gtext		d5, d6, #string_\1
	add.w		#88, d5
	v_gtext		d5, d6, #unit_\1
	sub.w		#88, d5
	ENDM

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

	DrawNextValue	G
	DrawNextValue	AP
	DrawNextValue	PE
	DrawNextValue	SemiMajorAxis
	DrawNextValue	SemiMinorAxis
	DrawNextValue	e
	DrawNextValue	VVI
	DrawNextValue	inc
	DrawNextValue	TAp
	DrawNextValue	TPe
	DrawNextValue	TrueAnomaly
	DrawNextValue	period

	;Fuel quantities
	move.w		#VALUE_COLUMN_2, d5
	move.w		d7, d6

	DrawNextValue	SolidFuel
	DrawNextValue	LiquidFuel
	DrawNextValue	Oxidizer
	DrawNextValue	ECharge

	;Surface info
	move.w		#VALUE_COLUMN_3, d5
	move.w		d7, d6

	DrawNextValue	Pitch
	DrawNextValue	Roll
	DrawNextValue	Heading
	DrawNextValue	Lat
	DrawNextValue	Lon
	DrawNextValue	RAlt
	DrawNextValue	Density
	DrawNextValue	Vsurf

	RTS

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

***************************
	include	include/FLOAT.I

	SECTION DATA
handle_main_window	dc.w	0

rectangleIndex		dc.w	0
rectanglesInList	dc.w	0

updateDataFlag	dc.b	0

msgKSP			dc.b	"Kerbal Space Packet",0
msgInfoBar		dc.b	" Kerbal Space Packet",0
msgProcessing	dc.b	" Processing packet data...",0

msgAbout		dc.b	"[2][Kerbal Mission Control||By Luigi Thirty, 2016][Okay]"

mainWindowResource 		dc.b	"RESOURCE\\POLYGON.RSC",0
mainWindowMenuAddress	dc.l	0


	SECTION BSS
currentRectangleX	dc.w	0
currentRectangleY	dc.w	0
currentRectangleW	dc.w	0
currentRectangleH	dc.w	0

FONT_6X6	equ 8
FONT_8X8 	equ 9
FONT_8X16 	equ 10
FONT_16X32 	equ 20
