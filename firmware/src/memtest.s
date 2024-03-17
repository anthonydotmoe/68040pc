; vim:noet:sw=8:ts=8:sts=8:ai:syn=asm68k

start_addr	equ	$00000000
test_pattern	equ	$AAAAAAAA
inc_size	equ	$00001000

	section	.text

; Detect amount of memory from base address
; A0 - (Input)	Base address
; A1 - (Output) Detected end of memory
detect_memory::
		move.l	#test_pattern,d0
		move.l	#$FFFFFFFF,d7

.detect_loop:
		; Attempt to write the test pattern
		move.l	d0,(a0)
		; Read back the value
		move.l	(a0),d1
		; Compare
		cmp.l	d0,d1
		bne	.detect_end

		; Increment address and try the next pattern
		add.l	#inc_size,a0
		eor.l	d7,d0
		bra	.detect_loop

.detect_end:
		sub.l	#inc_size,a0
		move.l	a0,a1

		rts

; Test entirety of memory from base address to size detected
; A0 - (Input)  Start address
; A1 - (Input)  End address
; D0 - (Output) Status: 0 = success, 1 = failure
; A0 - (Output, if failure) Address of failure
test_memory::
		move.l	#test_pattern,d1

.test_loop:
		cmp.l	a0,a1		; Check if we've reached the end of memory
		bge	.test_end

		; Write, read back, and compare
		;
		; The post increment is used instead of adding #$4 to a0 just to
		; save cycles. Normally, memory works.
		move.l	d1,(a0)
		move.l	(a0)+,d0	; Increment a0 after we write to it
		cmp.l	d0,d1
		bne	.test_fail

		; Swap pattern
		eor.l	d7,d1
		bra	.test_loop

.test_fail:
		sub.l	#4,a0		; Set A0 back to bad address
		moveq	#1,d0		; return failure
		rts

.test_end:
		moveq	#0,d0		; return success
		rts
