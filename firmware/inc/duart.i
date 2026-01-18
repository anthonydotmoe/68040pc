; vim:noet:sw=8:ts=8:sts=8:ai:syn=asm68k

DUART_BASE	equ	$20000000

MR1A		equ	$00		; RW	Mode register 1
MR2A		equ	$00		; RW	Mode register 2
SRA		equ	$01		; R	Status register
CSRA		equ	$01		; W	Clock select register
CRA		equ	$02		; W	Command register
RBA		equ	$03		; R	Receive buffer A
TBA		equ	$03		; W	Transmit buffer A
ACR		equ	$04		; W	Auxiliary control Register
ISR		equ	$05		; R	Interrupt status register
IMR		equ	$05		; R	Interrupt mask register
CTU		equ	$06		; RW	Counter/Timer upper register
CTL		equ	$07		; RW	Counter/Timer lower register
MR1B		equ	$08		; RW	Mode register 1
MR2B		equ	$08		; RW	Mode register 2
SRB		equ	$09		; R	Status register
CSRB		equ	$09		; W	Clock select register
CRB		equ	$0A		; W	Command register
RBB		equ	$0B		; R	Receive buffer B
TBB		equ	$0B		; W	Transmit buffer B
IVR		equ	$0C		; RW	Interrupt vector register
IP		equ	$0D		; R	Input port
OPCR		equ	$0D		; W	Output port configuration register
OPRSET		equ	$0E		; W	Output Port Register Set
OPRRST		equ	$0F		; W	Output Port Register Reset
