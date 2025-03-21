
	xref __stack_end
	xref __rom_base
	xref __bss_start
	xref __bss_end
	xref __rodata_end
	xref __data_start
	xref __data_end
	xref main

	section .text
	align 2

_start::
	move.w	#$2700,sr		; Disable interrupts
	movea.l	#__stack_end,sp		; Set stack pointer
	movea.l #__rom_base,a0		; Set VBR to beginning of ROM
	movec	a0,vbr			; ...

	; Initialize bss area
clearbss:
	movea.l #__bss_start,a0
	movea.l	#__bss_end,a1
.loop:
	cmpa.l	a1,a0			; check if start < end
	bge	.end

	clr.l	(a0)+			; clear addr
	bra	.loop
.end:

	; Copy initialized data from ROM to RAM
initrodata:
	movea.l #__rodata_end,a0	; src address
	movea.l #__data_start,a1	; dst start address
	movea.l	#__data_end,a2		; dst end address

.loop:
	cmpa.l	a2,a1			; check if start < end
	bge	.end

	move.l	(a0)+,(a1)+		; copy from ROM to RAM
	bra	.loop

.end:
	; Jump to main
jmp_to_main:
	jmp	main

__exc_DefaultExceptionHandler::
	stop	#$2700
	bra	*
