; vim:noet:sw=8:ts=8:sts=8:ai:syn=asm68k

	include "sys.i"


	section .bss

INT1_CHECK:
		ds.l	1
INT2_CHECK:
		ds.l	1
INT3_CHECK:
		ds.l	1
INT4_CHECK:
		ds.l	1
INT5_CHECK:
		ds.l	1
INT6_CHECK:
		ds.l	1
INT7_CHECK:
		ds.l	1

	section .bss.vectors

RAMVECTORS:
		dcb.l	256

	section	.vectors

VECTORS:
	org	ROM
		dc.l	INITIAL_SP	;  0
		dc.l	RESET		;  1
		dc.l	VEC_BUSFAULT	;  2
		dc.l	VEC_ADERROR	;  3
		dc.l	VEC_ILLINSTR	;  4
		dc.l	VEC_DIVBY0	;  5
		dc.l	VEC_CHK		;  6
		dc.l	VEC_TRAPV	;  7
		dc.l	VEC_PRIVVIOL	;  8
		dc.l	VEC_TRACE	;  9
		dc.l	VEC_LINE1010	; 10
		dc.l	VEC_LINE1111	; 11
		dc.l	VEC_RESERVED	; 12
		dc.l	VEC_CCPUVIOL	; 13 - Coprocessor Protocol Violation (68020/30)
		dc.l	VEC_FMTERROR	; 14
		dc.l	VEC_UNINIVEC	; 15
	rept	8
		dc.l	VEC_RESERVED	; 16-23
	endr
		dc.l	VEC_SPURIOUS	; 24
		dc.l	VEC_AUTOVEC1	; 25
		dc.l	VEC_AUTOVEC2	; 26
		dc.l	VEC_AUTOVEC3	; 27
		dc.l	VEC_AUTOVEC4	; 28
		dc.l	VEC_AUTOVEC5	; 29
		dc.l	VEC_AUTOVEC6	; 30
		dc.l	VEC_AUTOVEC7	; 31
		dc.l	VEC_TRAP0	; 32
		dc.l	VEC_TRAP1	; 33
		dc.l	VEC_TRAP2	; 34
		dc.l	VEC_TRAP3	; 35
		dc.l	VEC_TRAP4	; 36
		dc.l	VEC_TRAP5	; 37
		dc.l	VEC_TRAP6	; 38
		dc.l	VEC_TRAP7	; 39
		dc.l	VEC_TRAP8	; 40
		dc.l	VEC_TRAP9	; 41
		dc.l	VEC_TRAP10	; 42
		dc.l	VEC_TRAP11	; 43
		dc.l	VEC_TRAP12	; 44
		dc.l	VEC_TRAP13	; 45
		dc.l	VEC_TRAP14	; 46
		dc.l	VEC_TRAP15	; 47
	rept	8
		dc.l	VEC_RESERVED	; 48-55 - Floating point exceptions
	endr
		dc.l	VEC_RESERVED	; 56 - MMU Configuration Error (68030)
		dc.l	VEC_RESERVED	; 57 - MMU Illegal Operation Error (68851)
		dc.l	VEC_RESERVED	; 58 - MMU Access Violation (68851)
	rept	5
		dc.l	VEC_RESERVED	; 59-63 - Reserved
	endr
		; User deviced vectors (192)

	section	.text

RESET:

DELAY10000:
		move.l	#10000,d2	; Wait for a bit (for some reason)
.1:
		dbra	d2,.1

TEST_INTS:
		; Clear test bits
		movea.l	#INT1_CHECK,a0
		clr.l	$00(a0)
		clr.l	$04(a0)
		clr.l	$08(a0)
		clr.l	$0c(a0)
		clr.l	$10(a0)
		clr.l	$04(a0)
		clr.l	$08(a0)

		; Initiate interrupts to be autovectored through FPGA
		movea.l	#FPGA_BASE,a1
		move.b	#1,F_INT(a1)
		nop
		move.b	#2,F_INT(a1)
		nop
		move.b	#3,F_INT(a1)
		nop
		move.b	#4,F_INT(a1)
		nop
		move.b	#5,F_INT(a1)
		nop
		move.b	#6,F_INT(a1)
		nop
		move.b	#7,F_INT(a1)
		nop

		; Print message to screen for each interrupt
		; printf("int %d: %s", int_no, status);
		;
		; push status_str
		; push int_no
		; push "format string"

		tst	$00(a0)
		beq	.no_interrupt
		pea	str_ok
		bra	.2
.no_interrupt:	pea	str_fail
.2:		move.l	#0,-(sp)
		pea	str_int_n
		jsr	printf_
		add.l	#12,sp

INIT_DUART:
		
		movea.l	#DUART_BASE,a0
		move.b	#$00,IMR(a0)	; reset interrupt mask register

		; Initialize channel A
		move.b	#$10,CRA(a0)	; reset mode register pointer
		move.b	#$13,MR1A(a0)	; no parity, 8 bits/char
		move.b	#$07,MR2A(a0)	; 1 stop bit
		move.b	#$BB,CSRA(a0)	; 9600-baud XMIT and RCV
		move.b	#$20,CRA(a0)	; reset the receiver
		move.b	#$30,CRA(a0)	; reset the transmitter
		move.b	#$05,CRA(a0)	; enable XMIT and RCV

		; Initialize channel B
		move.b	#$10,CRB(a0)	; reset mode register pointer
		move.b	#$13,MR1B(a0)	; no parity, 8 bits/char
		move.b	#$07,MR2B(a0)	; 1 stop bit
		move.b	#$BB,CSRB(a0)	; 9600-baud XMIT and RCV
		move.b	#$20,CRB(a0)	; reset the receiver
		move.b	#$30,CRB(a0)	; reset the transmitter
					; Channel B is disabled

TEST_MEMORY:
		xref	detect_memory
		xref	test_memory

		move.l	#SRAM,a0	; Base address

		; TODO: Using printf requires working RAM. I just hope RAM works so I can see something here
		move.l	a0,-(sp)
		pea	str_membase
		jsr	printf_
		add.l	#4,sp
		move.l	(sp)+,a0	; Get membase back from stack

		jsr	detect_memory	; A0 input - memory base address
		; Now A1 has the detected end of memory
		
		; Print the supposed end of memory
		move.l	a1,-(sp)
		pea	str_memdet
		jsr	printf_
		add.l	#4,sp
		move.l	(sp)+,a1	; Get memory end back from stack

		; Test memory
		jsr	test_memory
		tst.l	d0
		beq	.memtest_ok
		pea	str_fail
		bra	.print_result
.memtest_ok:	
		pea	str_ok
.print_result:
		pea	str_memtest_s
		jsr	printf_
		add.l	#8,sp
		
COPY_VECTORS:
		moveq.l	#$FF,d0		; Load count 256 - 1 vectors
		move.l	#VECTORS,a0	; ROM base in a0
		move.l	#RAMVECTORS,a1	; RAM base in a1
.loop:
		move.l	(a0)+,(a1)+	; move a vector
		dbra	d0,.loop	; decrement d0 and loop (executes 256 times)

		; now we can move the VBR to SRAM
		move.l	#RAMVECTORS,a0
		movec.l	a0,vbr


FPU_IDENT:


		jsr	get_fpu		; d0 = 1: FPU, 0: LC (no FPU)
		move.b	d0,d0
		beq	.no_fpu
		pea	str_cpu_b
		jmp	.print
.no_fpu:	pea	str_cpu_lc
.print:		pea	str_cpu
		jsr	printf_
		add.l	#8,sp

DIE:		bra	DIE

		even


VEC_AUTOVEC1:
		move.l	#1,INT1_CHECK
		rte
VEC_AUTOVEC2:
		move.l	#1,INT2_CHECK
		rte
VEC_AUTOVEC3:
		move.l	#1,INT3_CHECK
		rte
VEC_AUTOVEC4:
		move.l	#1,INT4_CHECK
		rte
VEC_AUTOVEC5:
		move.l	#1,INT5_CHECK
		rte
VEC_AUTOVEC6:
		move.l	#1,INT6_CHECK
		rte
VEC_AUTOVEC7:
		move.l	#1,INT7_CHECK
		rte
VEC_ILLINSTR:
VEC_BUSFAULT:
VEC_ADERROR:
VEC_DIVBY0:
VEC_CHK:
VEC_TRAPV:
VEC_PRIVVIOL:
VEC_TRACE:
VEC_LINE1010:
VEC_LINE1111:
VEC_RESERVED:
VEC_CCPUVIOL:
VEC_FMTERROR:
VEC_UNINIVEC:
VEC_SPURIOUS:
VEC_TRAP0:
VEC_TRAP1:
VEC_TRAP2:
VEC_TRAP3:
VEC_TRAP4:
VEC_TRAP5:
VEC_TRAP6:
VEC_TRAP7:
VEC_TRAP8:
VEC_TRAP9:
VEC_TRAP10:
VEC_TRAP11:
VEC_TRAP12:
VEC_TRAP13:
VEC_TRAP14:
VEC_TRAP15:
		bra	VEC_RESERVED

_putchar::
		move.l	4(sp),d0		; Get char argument
		movea.l	DUART_BASE,a0		; DUART_BASE address in a0
.1		btst.b	#2,SRA(a0)		; Check if SR[2] is zero
		beq	.1			; If so, check again

		move.b	d0,TBA(a0)		; Move char to transmit buffer
		rts

get_fpu:	; d0 = get_fpu(void)
		; REQUIRES VBR is located in RAM
		link	a5,#0
		movec	vbr,a1		; get VBR
		move.w	sr,-(sp)	; save IPL
		move.l	$2c(a1),-(sp)	; save old trap vector (Line F)
		or.w	#$700,sr	; disable interrupts
		move.l	#.1,$2c(a1)	; set .1 as new vector
		move.l	sp,a0		; save stack pointer
		moveq.l	#0,d0		; value with exception
		nop
		fnop			; is an FPU present
		nop
		moveq.l	#1,d0		; value if we come here
.1		move.l	a0,sp		; restore stack pointer
		move.l	(sp)+,$2c(a1)	; restore trap vector
		move.w	(sp)+,sr	; restore IPL
		rts

	section .rodata

str_cpu:	dc.b	"CPU: Motorola 68%s040\n",0
		even
str_cpu_lc:	dc.b	"LC",0
		even
str_cpu_b:	dc.b	0
		even
str_int_n:	dc.b	"Interrupt %d: %s\n",0
		even
str_ok:		dc.b	"OK!",0
		even
str_fail:	dc.b	"FAILED",0
		even
str_membase:	dc.b	"Memory base: %08x\n",0
		even
str_memdet:	dc.b	"Memory end?: %08x\n",0
		even
str_memok:	dc.b	"Memory end?: %08x\n",0
		even
str_memtest_s:	dc.b	"Memory test: %s\n",0
		even
