	SECTION CODE
	xdef handle_surface_map_window

	xdef CreateSurfaceMapWindow
	xdef RedrawSurfaceMapWindow
	xdef MoveSurfaceMapWindow
	xdef MenuSelectedSurfaceMapWindow
	xdef DrawMapGrid
	xdef DrawRectangle
	xdef PlotLatLongOnMapGrid
	xdef LatLongLabels
	xdef LongitudeToString
	xdef LatitudeToString
	xdef LoadKerbinMap
	xdef DrawKerbinMap
	xdef StringToPackedBCD
	xdef DoneChecking
	xdef checkHundreds
	xdef checkTens
	xdef checkOnes
	xdef PackedBCDToBinary

	xref aes_intin
	xref WF_NAME
	xref WF_INFO

	include include/STMACROS.I
	include	include/GEMMACRO.I
	include include/GEMDOS.I

Wind_Set_FourArgs	MACRO
	move.w		\1, aes_intin+4
	move.w		\2, aes_intin+6
	move.w		\3, aes_intin+8
	move.w		\4, aes_intin+10
	ENDM

PackedBCDToBinary:
;D0=Four digit BCD number.
;D2=BCD number converted to binary.
    moveq   #0,d2       ;Clear conversion register.
    moveq   #3,d7       ;Number of BCD digits-1.
.loop
    rol.w   #4,d0       ;Move top digit to bottom.
    move.w  d0,d1       ;Copy BCD number.
    and.w   #15,d1      ;Keep only bottom digit.
    mulu.w  #10,d2      ;Make room to add digit to binary number.
    add.w   d1,d2       ;Add digit to binary number.
    dbra    d7,.loop

	RTS

StringToPackedBCD:
	clr.l	d0
	clr.l	d1
	clr.l	d2
	clr.l	d7

	;Input string is in a0 - 10 characters long
    move.b  hundredsOffset(a0), d0
    move.b  tensOffset(a0), d1
    move.b  onesOffset(a0), d2
        
    sub.b   #$30, d0
    sub.b   #$30, d1
    sub.b   #$30, d2
    
checkHundreds:
    cmp.b   #$F0, d0 ;space
    beq     .clearHundreds
    cmp.b   #$FD, d0
    beq     .negateHundreds
	jmp		checkTens
    
.clearHundreds:
    move.b  #0, d0
    jmp     checkTens
    
.negateHundreds:
    move.b  #0, d0
    move.b  #1, bcdNegateFlag
    jmp     checkTens
    
checkTens:
    cmp.b   #$F0, d1 ;space
    beq     .clearTens
    cmp.b   #$FD, d1
    beq     .negateTens
	jmp		checkOnes
    
.clearTens:
    move.b  #0, d1
    jmp     checkOnes
    
.negateTens:
    move.b  #0, d1
    move.b  #1, bcdNegateFlag
    jmp     checkOnes

checkOnes:
    cmp.b   #$F0, d2 ;space
    beq     .clearOnes
    cmp.b   #$FD, d2
    beq     .negateOnes
	jmp		DoneChecking    

.clearOnes:
    move.b  #0, d2
    jmp     DoneChecking
    
.negateOnes:
    move.b  #0, d2
    move.b  #1, bcdNegateFlag
    jmp     DoneChecking
    
DoneChecking:
    rol.l   #4, d0
    or.b    d1, d0
    rol.l   #4, d0
    or.b    d2, d0

	RTS

CreateSurfaceMapWindow:
	AESClearIntIn
	AESClearAddrIn
	VDIClearIntIn
	VDIClearPtsIn

	wind_create #$001B, #20, #40, #400, #300
	move.w		d0, handle_surface_map_window

	move.l		#msgSurfaceMapTitle, aes_intin+4
	wind_set	handle_surface_map_window, #WF_NAME
	move.l		#msgSurfaceMapInfobar, aes_intin+4
	wind_set	handle_surface_map_window, #WF_INFO

	AESClearIntIn
	AESClearAddrIn

	;wind_open	handle_surface_map_window, #60, #80, #400, #300

LoadKerbinMap:
	;load the kerbin map image
	PUSHW	#0 ;read-only
	pea		kerbinMapFileName
	GEMDOS	f_open, 8
	move.w	d0, kerbinMapHandle

	;do we have a valid handle?
	cmp.w	#0, kerbinMapHandle
	bmi		KerbinMapMissing

	;check that this file is a BMP
	PEA		kerbinMapImage
	PUSHL	#10000
	PUSHW	kerbinMapHandle
	GEMDOS	f_read, 12

	vr_trnfm #kerbinMapMFDB, #kerbinMapVDIMFDB

	;close the file now that we don't need it anymore
	PUSHW	kerbinMapHandle
	GEMDOS	f_close, 4
	move.w	#0, kerbinMapHandle ;invalidate the handle

	RTS

******************************
KerbinMapMissing:
	lea		kerbinMapFileName, a0
	JSR		FileIsMissing
	;does not return

******************************
RedrawSurfaceMapWindow:

	graf_mouse	#256 ;mouse off
	wind_update	#1 ;begin update

.doWindGet:
	wind_get	handle_surface_map_window, #WF_WORKXYWH
	move.w		aes_intout+2, surface_map_window_work_x
	move.w		aes_intout+4, surface_map_window_work_y
	move.w		aes_intout+6, surface_map_window_work_w
	move.w		aes_intout+8, surface_map_window_work_h

.doVsClip:
	;wind_get returns X,Y,W,H. vs_clip wants X,Y and X,Y of the opposite corner
	move.w		surface_map_window_work_x, temp_coord1_x
	move.w		surface_map_window_work_y, temp_coord1_y

	move.w		surface_map_window_work_x, temp_coord2_x
	move.w		surface_map_window_work_y, temp_coord2_y

	move.w		surface_map_window_work_w, d0
	add.w		d0, temp_coord2_x
	move.w		surface_map_window_work_h, d0
	add.w		d0, temp_coord2_y

	;clip to the window's work area
	vs_clip		#1, temp_coord1_x, temp_coord1_y, temp_coord2_x, temp_coord2_y
	vsf_color	#0 ;white

	JSR			FillTempCoordsWithSurfaceMapWindowCorners

.copyWindowCoords:
	move.w		temp_coord1_x, ptsin
	move.w		temp_coord1_y, ptsin+2
	move.w		temp_coord2_x, ptsin+4
	move.w		temp_coord2_y, ptsin+6
	move.w		temp_coord3_x, ptsin+8
	move.w		temp_coord3_y, ptsin+10
	move.w		temp_coord4_x, ptsin+12
	move.w		temp_coord4_y, ptsin+14

	v_fillarea	#4

	move.w		gr_hhchar, d0
	move.w		surface_map_window_work_x, d1
	move.w		surface_map_window_work_y, d2
	JSR			DrawMapGrid

	wind_update	#0 ;end update
	graf_mouse	#257 ;mouse on
	RTS

DrawMapGrid:
	;d0 = character height
	;d1 = window top left X
	;d2 = window top left Y

	vsf_color	#1 ;black
	vswr_mode	#1
	vsf_interior #2
	vsf_style	#2

	lea			mapGridRectangles, a6
	move.b		#20, mapRectanglesLeft

DrawMapRectangle:
	move.w		(a6)+, d0 ;top left X
	move.w		(a6)+, d1 ;top left Y
	move.w		(a6)+, d2 ;bottom right X
	move.w		(a6)+, d3 ;bottom right Y
	
	move.w		surface_map_window_work_x, d4
	add.w		d4, d0
	add.w		d4, d2
	move.w		surface_map_window_work_y, d5
	add.w		d5, d1
	add.w		d5, d3

	v_bar		d0, d1, d2, d3

	subq.b		#1, mapRectanglesLeft
	cmp.b		#0, mapRectanglesLeft
	bne			DrawMapRectangle

DrawMapLabels:
	VDIClearIntIn
	VDIClearPtsIn
	vst_point	#FONT_6X6

	move.w		surface_map_window_work_x, d4
	move.w		surface_map_window_work_y, d5
	add.w		#375, d4
	add.w		#12, d5
	v_gtext		d4, d5, #lbl90deg

	add.w		#30, d5
	v_gtext		d4, d5, #lbl60N

	add.w		#30, d5
	v_gtext		d4, d5, #lbl30N

	add.w		#30, d5
	v_gtext		d4, d5, #lbl0deg

	add.w		#30, d5
	v_gtext		d4, d5, #lbl30S

	add.w		#30, d5
	v_gtext		d4, d5, #lbl60S

	add.w		#30, d5
	v_gtext		d4, d5, #lbl90deg

	move.w		surface_map_window_work_x, d4
	move.w		surface_map_window_work_y, d5
	add.w		#2, d4
	add.w		#197, d5
	v_gtext		d4, d5, #lbl180deg

	move.w		surface_map_window_work_x, d4
	add.w		#30, d4
	v_gtext		d4, d5, #lbl150W

	move.w		surface_map_window_work_x, d4
	add.w		#60, d4
	v_gtext		d4, d5, #lbl120W

	move.w		surface_map_window_work_x, d4
	add.w		#95, d4
	v_gtext		d4, d5, #lbl90W

	move.w		surface_map_window_work_x, d4
	add.w		#125, d4
	v_gtext		d4, d5, #lbl60W

	move.w		surface_map_window_work_x, d4
	add.w		#155, d4
	v_gtext		d4, d5, #lbl30W

	move.w		surface_map_window_work_x, d4
	add.w		#189, d4
	v_gtext		d4, d5, #lbl0deg

	move.w		surface_map_window_work_x, d4
	add.w		#215, d4
	v_gtext		d4, d5, #lbl30E

	move.w		surface_map_window_work_x, d4
	add.w		#245, d4
	v_gtext		d4, d5, #lbl60E

	move.w		surface_map_window_work_x, d4
	add.w		#275, d4
	v_gtext		d4, d5, #lbl90E

	move.w		surface_map_window_work_x, d4
	add.w		#300, d4
	v_gtext		d4, d5, #lbl120E

	move.w		surface_map_window_work_x, d4
	add.w		#330, d4
	v_gtext		d4, d5, #lbl150E

	move.w		surface_map_window_work_x, d4
	add.w		#362, d4
	v_gtext		d4, d5, #lbl180deg

HandleLatitudeAndLongitude:
	lea			string_Lon, a0
	JSR			StringToPackedBCD
	JSR			PackedBCDToBinary
	PUSHW		d2

	lea			string_Lat, a0
	JSR			StringToPackedBCD
	JSR			PackedBCDToBinary
	move.w		d2, d1

	POPW		d2
	move.w		d2, d0
	
	;if longitude is above 180, subtract 360 to produce west
	cmp.w		#180, d0
	bcs			.longitudeIsEast

	sub.w		#360, d0

.longitudeIsEast:
	PUSHREG		d0-d3
	vst_point	#FONT_8X16
	POPREG		d0-d3
	JSR			PlotLatLongOnMapGrid

	JMP			LatLongLabels

LongitudeToString:
	lea			stringLongitude, a0

	clr.l		d1
	clr.l		d2
	clr.l		d3
	clr.l		d4

	move.w		#-75, d2 ;75 degrees W
	neg.w		d2
	move.l		#0, d3
	move.b		#0, d1
	move.w		d2, d4

.loop
	ext.l		d4
	divu		#10, d4
	swap		d4
	move.b		d4, d5
	lsl.l		d1, d5
	or.l		d5, d3
	addi.b		#4, d1
	swap		d4
	cmpi.w		#0, d4
	bne			.loop

LatitudeToString:
	clr.l		d1
	clr.l		d2
	clr.l		d3
	clr.l		d4

	move.w		#0, d2 ;0 degrees
	move.l		#0, d3
	move.b		#0, d1
	move.w		d2, d4

.loop
	ext.l		d4
	divu		#10, d4
	swap		d4
	move.b		d4, d5
	lsl.l		d1, d5
	or.l		d5, d3
	addi.b		#4, d1
	swap		d4
	cmpi.w		#0, d4
	bne			.loop

latitudeLabelX equ 10
latitudeLabelY equ 220

LatLongLabels:
	VDIClearIntIn
	VDIClearPtsIn

	move.w	surface_map_window_work_x, d5
	move.w	surface_map_window_work_y, d6
	add.w	#latitudeLabelX, d5
	add.w	#latitudeLabelY, d6
	v_gtext	d5, d6, #msgLatitude

	move.w	surface_map_window_work_x, d5
	move.w	surface_map_window_work_y, d6
	add.w	#latitudeLabelX, d5
	add.w	#latitudeLabelY, d6
	add.w	#100, d5
	v_gtext d5, d6, #string_Lat

	move.w	surface_map_window_work_x, d5
	move.w	surface_map_window_work_y, d6
	add.w	#latitudeLabelX, d5
	add.w	#latitudeLabelY, d6
	add.w	gr_hhchar, d6
	v_gtext	d5, d6, #msgLongitude

	move.w	surface_map_window_work_x, d5
	move.w	surface_map_window_work_y, d6
	add.w	#latitudeLabelX, d5
	add.w	#latitudeLabelY, d6
	add.w	gr_hhchar, d6
	add.w	#100, d5
	v_gtext d5, d6, #string_Lon

DrawKerbinMap:

	;source: copy a rectangle from (0,0) to (360,180)
	move.w	#0, ptsin+0
	move.w	#0,	ptsin+2
	move.w	#360, ptsin+4
	move.w	#180, ptsin+6

	;destination: copy to a rectangle from (10,10) to (370,190) relative to the window position
	move.w	surface_map_window_work_x, ptsin+8
	move.w	surface_map_window_work_y, ptsin+10
	move.w	surface_map_window_work_x, ptsin+12
	move.w	surface_map_window_work_y, ptsin+14

	add.w	#10, ptsin+8
	add.w	#10, ptsin+10
	add.w	#370, ptsin+12
	add.w	#190, ptsin+14

	vro_cpyfm	#7, #kerbinMapVDIMFDB, #screenMemoryMFDB

	RTS

******************************
PlotLatLongOnMapGrid:
	;d0 = longitude degrees. negative = W, positive = E
	;d1 = latitude degrees. negative = N, positive = S

	;KSC is 6 deg S, 74 deg W

	PUSHREG		d0-d1
	vsf_style	#7
	POPREG		d0-d1

	add.w	#mapGridTopLeftX, d0
	add.w	#mapGridTopLeftY, d1
	add.w	surface_map_window_work_x, d0
	add.w	surface_map_window_work_y, d1

	;center the point
	add.w	#180, d0
	add.w	#90, d1

	v_circle	d0, d1, #5

	RTS

******************************
MoveSurfaceMapWindow:
	;Move the window.
	Wind_Set_FourArgs	EventBuffer+8, EventBuffer+10, EventBuffer+12, EventBuffer+14
	wind_set	handle_surface_map_window, #WF_CURRXYWH

	RTS

MenuSelectedSurfaceMapWindow:
	RTS

**
FillTempCoordsWithSurfaceMapWindowCorners:
	move.w		surface_map_window_work_x, temp_coord1_x
	move.w		surface_map_window_work_y, temp_coord1_y
	
	move.w		surface_map_window_work_x, temp_coord2_x
	move.w		surface_map_window_work_y,	temp_coord2_y
	move.w		surface_map_window_work_w, d0
	add.w		d0, temp_coord2_x

	move.w		surface_map_window_work_x, temp_coord3_x
	move.w		surface_map_window_work_y,	temp_coord3_y
	move.w		surface_map_window_work_w, d0
	add.w		d0, temp_coord3_x
	move.w		surface_map_window_work_h, d0
	add.w		d0, temp_coord3_y

	move.w		surface_map_window_work_x, temp_coord4_x
	move.w		surface_map_window_work_y,	temp_coord4_y
	move.w		surface_map_window_work_h, d0
	add.w		d0, temp_coord4_y

	RTS

************************************
GetCelestialBodyLabel:
	;SOI Number (decimal format: sun-planet-moon e.g. 130 = kerbin, 131 = mun)
	cmp.b	#130, value_SOINumber

	RTS

	SECTION DATA

	even
bcdBuffer	dc.b 4

handle_surface_map_window	dc.w	0
;top left coordinates
surface_map_window_work_x	dc.w	0
surface_map_window_work_y	dc.w	0
surface_map_window_work_w	dc.w	0
surface_map_window_work_h	dc.w	0

;Strings
msgSurfaceMapTitle 		dc.b "Surface Map",0
msgSurfaceMapInfobar 	dc.b " Kerbin Surface Map",0
msgLatitude				dc.b "Latitude :",0
msgLongitude			dc.b "Longitude:",0

msgPlanetKerbin	dc.b	"Kerbin",0
msgMoonMun		dc.b	"Mun",0

;Celestial body types
msgBodyMoon		dc.b	"Moon",0
msgBodyPlanet	dc.b	"Planet",0
	
lbl180deg	dc.b	"180",0
lbl150W		dc.b	"150W",0
lbl120W		dc.b	"120W",0
lbl90W		dc.b	"90W",0
lbl60W		dc.b	"60W",0
lbl30W		dc.b	"30W",0
lbl0deg		dc.b	"0",0
lbl30E		dc.b	"30E",0
lbl60E		dc.b	"60E",0
lbl90E		dc.b	"90E",0
lbl120E		dc.b	"120E",0
lbl150E		dc.b	"150E",0

lbl90deg	dc.b	"90",0
lbl60N		dc.b	"60N",0
lbl30N		dc.b	"30N",0
lbl30S		dc.b	"30S",0
lbl60S		dc.b	"60S",0

bcdNegateFlag dc.b 0

	even
kerbinMapHandle			dc.l 0
;kerbinMapFileName		dc.b "C:\\POLYGON\\KERBIN2.BMP",0
kerbinMapFileName		dc.b "GFX\\KERBIN2.BMP",0

	even
;Kerbin map MFDB structure.
kerbinMapMFDB:
kerbinMap_fd_addr	dc.l	kerbinMapImage+62 ;offset 3E starts the image
kerbinMap_fd_w		dc.w	360 ;360 wide
kerbinMap_fd_h		dc.w	180 ;180 tall
kerbinMap_wdwidth	dc.w	24 ;one line is 24 words long
kerbinMap_fd_stand	dc.w	0 ;device-specific format
kerbinMap_fd_nplanes dc.w	1 ;1 bitplane = 1bpp
kerbinMap_fd_r1		dc.w	0
kerbinMap_fd_r2		dc.w	0
kerbinMap_fd_r3		dc.w	0

;Kerbin map MFDB structure in VDI standard format.
kerbinMapVDIMFDB:
kerbinMap_vdi_fd_addr	dc.l	kerbinMapImage+62 ;offset 3E starts the image
kerbinMap_vdi_fd_w		dc.w	360 ;360 wide
kerbinMap_vdi_fd_h		dc.w	180 ;180 tall
kerbinMap_vdi_wdwidth	dc.w	24 ;one line is 24 words long
kerbinMap_vdi_fd_stand	dc.w	0 ;device-specific format
kerbinMap_vdi_fd_nplanes dc.w	1 ;1 bitplane = 1bpp
kerbinMap_vdi_fd_r1		dc.w	0
kerbinMap_vdi_fd_r2		dc.w	0
kerbinMap_vdi_fd_r3		dc.w	0

screenMemoryMFDB		dc.w	0 ;we just need a 0 there and VDI will know it's screen memory

barTopLeftX		dc.w 0
barTopLeftY		dc.w 0
barBottomRightX	dc.w 0
barBottomRightY	dc.w 0

mapGridTopLeftX equ 10
mapGridTopLeftY equ 10
mapGridWidth	equ 360
mapGridHeight	equ 180

mapRectanglesLeft	dc.b 0
negateBcdFlag		dc.b 0

	even
currentLatitude		dc.w 0
currentLongitude	dc.w 0

mapGridRectangles	dc.w  10, 10, 370, 11 	;90 degrees N
					dc.w  10, 40, 370, 41 	;60 degrees N
					dc.w  10, 70, 370, 71 	;30 degrees N
					dc.w  10, 100, 370, 101 ;0 degrees
					dc.w  10, 130, 370, 131 ;30 degrees S
					dc.w  10, 160, 370, 161 ;60 degrees S
					dc.w  10, 190, 370, 191 ;90 degrees S

					dc.w  10, 10, 11, 190
					dc.w  40, 10, 41, 190
					dc.w  70, 10, 71, 190
					dc.w  100, 10, 101, 190
					dc.w  130, 10, 131, 190
					dc.w  160, 10, 161, 190
					dc.w  190, 10, 191, 190
					dc.w  220, 10, 221, 190
					dc.w  250, 10, 251, 190
					dc.w  280, 10, 281, 190
					dc.w  310, 10, 311, 190
					dc.w  340, 10, 341, 190
					dc.w  370, 10, 371, 190

FONT_6X6	equ 8
FONT_8X8 	equ 9
FONT_8X16 	equ 10
FONT_16X32 	equ 20

hundredsOffset  equ 4
tensOffset      equ 5
onesOffset      equ 6

	section BSS
kerbinMapImage		ds.b 16384 ;reserve 16kb for the bitmap
kerbinMapVDIImage	ds.b 16384 ;reserve 16kb for the bitmap in VDI format

stringLatitude		ds.b 10
stringLongitude		ds.b 10
