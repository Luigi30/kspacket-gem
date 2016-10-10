	SECTION CODE

	public CheckSerialBuffer
	public DataInSerialBuffer
	public KSPPacketBuffer
	public ReadKSPPacket

	public serialDataUpdatedFlag

	include include/BIOS.I
	include	include/GEMDOS.I

CheckSerialBuffer: ;is there data waiting?
	B_Constat	dev_aux
	cmp.w		#0, d0
	beq			.done
	jmp			DataInSerialBuffer

.done:
	RTS

******************************************

DataInSerialBuffer:
	;Is this a KSPSerialIO packet header? ($BEEF)
	B_Conin		dev_aux
	cmp.b		#$BE, d0
	bne			.badHeader

	B_Conin		dev_aux
	cmp.b		#$EF, d0
	bne			.badHeader

	;We have a valid header.
	JMP			ReadKSPPacket

.badHeader
	RTS

ReadKSPPacket:
	clr.w		d7

	B_Conin		dev_aux ;read in the packet length
	move.b		d0, d7

	lea			KSPPacketBuffer, a6
	subq.b		#1, d7 ;subtract 1 from the length so we can use dbra

.readloop:
	B_Conin		dev_aux
	move.b		d0, (a6)+
	dbra		d7, .readloop

.done:
	;empty the serial buffer
	JSR			FlushSerialBuffer
	move.b		#1, serialDataUpdatedFlag

	RTS

******************************************
FlushSerialBuffer:
	B_Constat	dev_aux

	cmp.b	#0,d0 ;is the buffer empty?
	bne	.readchar ;no
	beq	.done	;yes

.readchar:
	B_Conin		dev_aux
	bra	FlushSerialBuffer

.done:
	rts

	SECTION DATA
serialDataUpdatedFlag	dc.b	0
KSPPacketBuffer			ds.b	256

	SECTION BSS
