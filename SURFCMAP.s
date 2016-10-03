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

	xref aes_intin
	xref WF_NAME
	xref WF_INFO

	include include/STMACROS.I
	include	include/GEMMACRO.I

Wind_Set_FourArgs	MACRO
	move.w		\1, aes_intin+4
	move.w		\2, aes_intin+6
	move.w		\3, aes_intin+8
	move.w		\4, aes_intin+10
	ENDM

CreateSurfaceMapWindow:
	AESClearIntIn
	AESClearAddrIn
	VDIClearIntIn
	VDIClearPtsIn

	wind_create #$001B, #20, #40, #520, #300
	move.w		d0, handle_surface_map_window

	move.l		#msgSurfaceMapTitle, aes_intin+4
	wind_set	handle_surface_map_window, #WF_NAME
	move.l		#msgSurfaceMapInfobar, aes_intin+4
	wind_set	handle_surface_map_window, #WF_INFO

	AESClearIntIn
	AESClearAddrIn

	wind_open	handle_surface_map_window, #60, #80, #520, #300

	RTS

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

.latitudeAndLongitude:
	move.w		#-74, d0 ;74 degrees W
	move.w		#6, d1 ;6 degrees S
	JSR			PlotLatLongOnMapGrid

	JMP			LatLongLabels

LongitudeToString:
	lea			stringLongitude, a0

	clr.l		d1
	clr.l		d2
	clr.l		d3
	clr.l		d4

	move.w		#-74, d2 ;74 degrees W
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

	move.w		#6, d2 ;6 degrees S
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

latitudeLabelX equ 10
latitudeLabelY equ 220

LatLongLabels:
	move.w	surface_map_window_work_x, d5
	move.w	surface_map_window_work_y, d6
	add.w	#latitudeLabelX, d5
	add.w	#latitudeLabelY, d6
	v_gtext	d5, d6, #msgLatitude

	move.w	surface_map_window_work_x, d5
	move.w	surface_map_window_work_y, d6
	add.w	#latitudeLabelX, d5
	add.w	#latitudeLabelY, d6
	add.w	#100, d6
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

	RTS

******************************
PlotLatLongOnMapGrid:
	;d0 = longitude degrees. negative = W, positive = E
	;d1 = latitude degrees. negative = N, positive = S

	;KSC is 6 deg S, 74 deg W

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

	SECTION DATA
bcdBuffer	dc.b 4

handle_surface_map_window	dc.w	0

;top left coordinates
surface_map_window_work_x	dc.w	0
surface_map_window_work_y	dc.w	0
surface_map_window_work_w	dc.w	0
surface_map_window_work_h	dc.w	0

;Strings
msgSurfaceMapTitle 		dc.b "Surface Map",0
msgSurfaceMapInfobar 	dc.b " This is a surface map!",0
msgLatitude				dc.b "Latitude :",0
msgLongitude			dc.b "Longitude:",0

barTopLeftX		dc.w 0
barTopLeftY		dc.w 0
barBottomRightX	dc.w 0
barBottomRightY	dc.w 0

mapGridTopLeftX equ 10
mapGridTopLeftY equ 10
mapGridWidth	equ 360
mapGridHeight	equ 180

mapRectanglesLeft	dc.b 0

	even
currentLatitude		dc.w 0
currentLongitude	dc.w 0

stringLatitude		ds.b 10
stringLongitude		ds.b 10

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

