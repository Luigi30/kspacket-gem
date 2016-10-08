	SECTION CODE

	public CheckSerialBuffer
	public DataInSerialBuffer

	include include/BIOS.I

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
	;Next byte will be the length of the packet.
	B_Conin		dev_aux
	move.b		d0, d7

	RTS
