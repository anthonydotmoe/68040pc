; vim:noet:sw=8:ts=8:sts=8:ai:syn=asm68k

	include "sys.inc"

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

RESET:
		move.l	#10000,d2	; Wait for a bit (for some reason)
.1:
		subq.l	#1,d2
		bne	.1

; Power-on Self Test
INIT_DUART:
		

CPU_IDENT:
; Define CPU types

; Lets try and figure out what we're running on
; First, we assume it's a 68040
; -- Init CPU type variable to 68040
; (Illegal instruction handler sets a global variable non-zero when it's called)
;
; Next, we see if a 68040 instruction executes
;
; Could do this:
;		lea	VECTORS,a0
;		move16	(a0),SRAM	; Copy 16 bytes from vectors to SRAM.
; Or this:
		move.l	#2,d7		; Skip two bytes if illegal
		cinva	bc		; Invalidate all I/D caches
;
; -- Check illegal instruction variable
;
; -- -- If zero, we are on 68040, exit.
;
; Non-zero, 
; -- Reset illegal instruction variable
; 
; Try a 68030 instruction
		move.l	#2,d7		; Skip two bytes if illegal
		move	ccr,d0		; (valid on 68010, 68020, 68030, 68040, CPU32)
;
; -- Check illegal instruction variable
;
; -- -- If non-zero, we are on 68000. Return
; -- -- If zero, we are on 68030 or lesser
;
; Try a 68020 exclusive instruction
; 
		move.l	#6,d7		; Skip two bytes if illegal
		callm	#0,DET_020_MODULE_HEADER
;
; -- Check illegal instruction variable
;
; -- -- If non-zero, we are on 68030. Return
; -- -- If zero, we are on 68020

DET_020_MODULE_HEADER:
		dc.b	%00000000	; 000: args on stack, $00: no access rights change
		dc.b	$00		; Empty access level, not used
		dc.w	$0000		; (Reserved, must be zero)
		dc.l	DET_020_MODULE	; Module entry word pointer
		; That should be enough for the CPU to work with
		; Ref pg. 9-16 MC68020UM.pdf

DET_020_MODULE:
		; Module entry word
		dc.b	%11110000,$00	; Don't load module data area pointer
					; (same as loading in a7, which gets overwritten)

		; We're running in a module now, lets get out of here!
		rtm	a7

VEC_ILLINSTR:
		; Skip the number of bytes given in d7.l and return
		add.l	d7,(2,sp)
		rte
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
VEC_AUTOVEC1:
VEC_AUTOVEC2:
VEC_AUTOVEC3:
VEC_AUTOVEC4:
VEC_AUTOVEC5:
VEC_AUTOVEC6:
VEC_AUTOVEC7:
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
