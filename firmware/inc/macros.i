; vim:noet:sw=8:ts=8:sts=8:ai:syn=asm68k

; Define macro for jsr without stack RAM
bl		macro
		lea	(.ret\@,pc),a6
		bra	\1
.ret\@:
		endm

; Return from subroutine to address in A6.
rl		macro
		jmp	(a6)
		endm

; Null terminated string
asciz:		macro
		rept	\#
		dc.b	\+
		endr
		dc.b	0
		even
		endm
