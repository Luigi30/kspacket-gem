	SECTION DATA

	public application_id

	public gr_handle
	public gr_hwchar
	public gr_hhchar
	public gr_hwbox
	public gr_hhbox

	public temp_coord1_x
	public temp_coord1_y
	public temp_coord2_x
	public temp_coord2_y
	public temp_coord3_x
	public temp_coord3_y
	public temp_coord4_x
	public temp_coord4_y

	public main_window_work_x
	public main_window_work_y
	public main_window_work_w
	public main_window_work_h

	;layout
	public COLUMN_1	
	public COLUMN_2	
	public COLUMN_3

	public VALUE_COLUMN_1
	public VALUE_COLUMN_2
	public VALUE_COLUMN_3

	;Pointers
	public GFX_BASE
	public GFX_LOGICAL_BASE	

	;Buffers
	public SerialBuffer
	public StringBuilding
	public EventBuffer

	;String buffers
	public PathName	
	public FileName	

	;Escape codes
	public ClearHome
	public PositionCursor
	public NewLine

	;event stuff
	public Event_MouseX
	public Event_MouseY
	public Event_MouseButtons
	public Event_MouseClickCount

	public Event_KeyboardSpecial
	public Event_KeyboardScancode

	public mainWindowIsOpen
	public surfaceMapWindowIsOpen

application_id		dc.w	0 ;AES ID

mainWindowIsOpen		dc.b 0
surfaceMapWindowIsOpen	dc.b 0

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

;top left coordinates
main_window_work_x	dc.w	0
main_window_work_y	dc.w	0
main_window_work_w	dc.w	0
main_window_work_h	dc.w	0

;layout
COLUMN_1	equ	0
COLUMN_2	equ	220
COLUMN_3	equ 400

VALUE_COLUMN_1	equ	80
VALUE_COLUMN_2	equ	310
VALUE_COLUMN_3	equ 480

;Pointers
GFX_BASE			dc.l	0
GFX_LOGICAL_BASE	dc.l	0

;Buffers
SerialBuffer	ds.b	256
StringBuilding	ds.b	128
EventBuffer		ds.b	16

Event_MouseX		dc.w	0
Event_MouseY		dc.w	0
Event_MouseButtons	dc.w	0
Event_MouseClickCount	dc.w	0

Event_KeyboardSpecial	dc.w	0
Event_KeyboardScancode	dc.w	0

;String buffers
PathName		ds.b	128
FileName		ds.b	128

;KSP packets
PacketDataBuffer	ds.b	256

;Escape codes
ClearHome		dc.b	$1B,"E",0
PositionCursor	dc.b	$1B,"Y",0
NewLine			dc.b	$0D,$0A,0

