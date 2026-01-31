
	section	.text

	align	3
; Routine to copy a memory block to a new place and jump to entry_addr.
; As long as this routine is allocated *after* the loaded kernel data,
; I think it should be fine.
copyandgo::	; copyandgo(entry_addr, dst, src, size)
					; move parameters to holding regs
		move.l	(sp)+,d2	; size  -> d2
		move.l	(sp)+,a3	; src   -> a3
		move.l	(sp)+,a4	; dst   -> a4
		move.l	(sp)+,a5	; entry -> a5

		move.l	a3,a0		; a0 (source) <- src
		move.l	a0,a2	
		add.l	d2,a2		; a2 (limit)  <- src + size
		move.l	a4,a1		; a1 (destination) <- dst

		; Copy
.copyloop:	cmp.l	a0,a2		; stop = (src != limit)
		beq	.copydone	; while (!stop)
		move.b	(a0)+,(a1)+	;   *dest++ = *source++
		bra	.copyloop

.copydone:	jmp	(a5)

copyandgo_end::
