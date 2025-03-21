OUTPUT_FORMAT("binary")

__rom_base	= 0x00000000;
__rom_size	= 2M;
__ram_base	= 0x30000000;
__ram_size	= 1M;

__stack_size	= 4K;

STARTUP(obj/crt0.o)
OUTPUT_ARCH(m68k)

__rom_end = (__rom_base + __rom_size);
__ram_end = (__ram_base + __ram_size);

__evt_org = __rom_base;
__evt_size = 0x400;
__text_org = __rom_base + __evt_size;
__text_size = __rom_size - __evt_size;
__data_org = __ram_base;
__data_size = __ram_size;


MEMORY {
	evt	(r!ax)	: ORIGIN = __evt_org, LENGTH = __evt_size
	text	(rx!w)	: ORIGIN = __text_org, LENGTH = __text_size
	data	(rwx!a)	: ORIGIN = __data_org, LENGTH = __data_size
}

SECTIONS {
	.evt : {
		LONG(__ram_end);
		LONG(ABSOLUTE(_start));

		LONG(DEFINED(_exc_BusError) ? ABSOLUTE(_exc_BusError) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_AddressError) ? ABSOLUTE(_exc_AddressError) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_IllegalInstruction) ? ABSOLUTE(_exc_IllegalInstruction) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_ZeroDivide) ? ABSOLUTE(_exc_ZeroDivide) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_CHKInstruction) ? ABSOLUTE(_exc_CHKInstruction) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_TRAPVInstruction) ? ABSOLUTE(_exc_TRAPVInstruction) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_PrivilegeViolation) ? ABSOLUTE(_exc_PrivilegeViolation) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trace) ? ABSOLUTE(_exc_Trace) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Line1010Emulator) ? ABSOLUTE(_exc_Line1010Emulator) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Line1111Emulator) ? ABSOLUTE(_exc_Line1111Emulator) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_HardwareBreakpoint) ? ABSOLUTE(_exc_HardwareBreakpoint) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_CoprocessorProtocolViolation) ? ABSOLUTE(_exc_CoprocessorProtocolViolation) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_FormatError) ? ABSOLUTE(_exc_FormatError) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_UninitializedInterrupt) ? ABSOLUTE(_exc_UninitializedInterrupt) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(0);
		LONG(0);
		LONG(0);
		LONG(0);
		LONG(0);
		LONG(0);
		LONG(0);
		LONG(0);
		LONG(DEFINED(_exc_SpuriousInterrupt) ? ABSOLUTE(_exc_SpuriousInterrupt) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Autovector1) ? ABSOLUTE(_exc_Autovector1) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Autovector2) ? ABSOLUTE(_exc_Autovector2) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Autovector3) ? ABSOLUTE(_exc_Autovector3) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Autovector4) ? ABSOLUTE(_exc_Autovector4) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Autovector5) ? ABSOLUTE(_exc_Autovector5) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Autovector6) ? ABSOLUTE(_exc_Autovector6) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Autovector7) ? ABSOLUTE(_exc_Autovector7) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap0) ? ABSOLUTE(_exc_Trap0) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap1) ? ABSOLUTE(_exc_Trap1) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap2) ? ABSOLUTE(_exc_Trap2) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap3) ? ABSOLUTE(_exc_Trap3) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap4) ? ABSOLUTE(_exc_Trap4) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap5) ? ABSOLUTE(_exc_Trap5) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap6) ? ABSOLUTE(_exc_Trap6) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap7) ? ABSOLUTE(_exc_Trap7) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap8) ? ABSOLUTE(_exc_Trap8) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap9) ? ABSOLUTE(_exc_Trap9) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap10) ? ABSOLUTE(_exc_Trap10) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap11) ? ABSOLUTE(_exc_Trap11) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap12) ? ABSOLUTE(_exc_Trap12) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap13) ? ABSOLUTE(_exc_Trap13) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap14) ? ABSOLUTE(_exc_Trap14) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_Trap15) ? ABSOLUTE(_exc_Trap15) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_FPBranchOrSetUnorderedCondition) ? ABSOLUTE(_exc_FPBranchOrSetUnorderedCondition) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_FPInexactResult) ? ABSOLUTE(_exc_FPInexactResult) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_FPZeroDivide) ? ABSOLUTE(_exc_FPZeroDivide) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_FPUnderflow) ? ABSOLUTE(_exc_FPUnderflow) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_FPOperandError) ? ABSOLUTE(_exc_FPOperandError) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_FPOverflow) ? ABSOLUTE(_exc_FPOverflow) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_FPSignalingNAN) ? ABSOLUTE(_exc_FPSignalingNAN) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_FPUnimplementedDataType) ? ABSOLUTE(_exc_FPUnimplementedDataType) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_MMUConfigurationError) ? ABSOLUTE(_exc_MMUConfigurationError) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_MMUIllegalOperation) ? ABSOLUTE(_exc_MMUIllegalOperation) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(DEFINED(_exc_MMUAccessLevelViolation) ? ABSOLUTE(_exc_MMUAccessLevelViolation) : ABSOLUTE(__exc_DefaultExceptionHandler));
		LONG(0);
		LONG(0);
		LONG(0);
		LONG(0);
		LONG(0);
	} > evt

	.text : {
		__text_start = .;
		*(.text .text.*)
		. = ALIGN(0x10);
		__text_end = .;
	} > text

	.rodata : AT(__text_end) {
		__rodata_start = .;
		*(.rodata .rodata.*)
		. = ALIGN(0x10);
		__rodata_end = .;
	} > text

	.data : AT(__rodata_end) {
		__data_start = .;
		*(.data .data.*)
		. = ALIGN(0x10);
		__data_end = .;
	} > data

	.bss : {
		__bss_start = .;
		*(.bss .bss.*)
		*(COMMON)
		. = ALIGN(0x10);
		__bss_end = .;
	} > data

	.heap : {
		__heap_start = .;
		. += (__ram_size - __stack_size - SIZEOF(.bss) - SIZEOF(.data));
		__heap_end = .;
	} > data

	.stack : {
		__stack_start = .;
		. += __stack_size;
		__stack_end = .;
	} > data
}
