; vim:noet:sw=8:ts=8:sts=8:ai:syn=asm68k

ROMSIZE		equ	$00200000	; 16 MEGA POWER
SRAMSIZE	equ	$00100000	; 1MB
RAMEND		equ	SRAM+SRAMSIZE
INITIAL_SP	equ	RAMEND

; Base addresses
ROM		equ	$00000000
SRAM		equ	$40000000
