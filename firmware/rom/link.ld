OUTPUT_FORMAT("binary")

eram_bot	= 0x00000000;
eram_top	= 0x1FFFFFFF;

dram_bot	= 0x20000000;
dram_top	= 0x27FFFFFF;

rom_bot		= 0x28000000;
rom_top		= 0x2FFFFFFF;

sram_bot	= 0x30000000;
sram_top	= 0x3007FFFF;

stack_top	= sram_top + 1;

/*
 * Memory is divided into (32) 128MB chunks
 *
 * |Page| A[31:27] | Description        | Address Space             |
 * |----|---------/---------------------|---------------------------|
 * |0	| 00000	| Boot ROM		| 0x0000_0000 - 0x07FF_FFFF |
 * |1	| 00001	| On-board SRAM		| 0x0800_0000 - 0x0FFF_FFFF |
 * |2	| 00010	| On-board DRAM		| 0x1000_0000 - 0x17FF_FFFF |
 * |3-6 | 00011 | (Blank)		| 0x1800_0000 - 0x37FF_FFFF |
 * |7	| 00111	| System Registers	| 0x3800_0000 - 0x3FFF_FFFF |
 * |8-15| 01000	| Expansion Area	| 0x4000_0000 - 0x7FFF_FFFF |
 * |16	| 10000	| (Blank)		| 0x8000_0000 - 0x87FF_FFFF |
 * |17	| 10001	| (Blank)		| 0x8800_0000 - 0x8FFF_FFFF |
 * |18	| 10010	| (Blank)		| 0x9000_0000 - 0x97FF_FFFF |
 * |19	| 10011	| (Blank)		| 0x9800_0000 - 0x9FFF_FFFF |
 * |20	| 10100	| (Blank)		| 0xA000_0000 - 0xA7FF_FFFF |
 * |21	| 10101	| (Blank)		| 0xA800_0000 - 0xAFFF_FFFF |
 * |22	| 10110	| (Blank)		| 0xB000_0000 - 0xB7FF_FFFF |
 * |23	| 10111	| EXP Configuration	| 0xB800_0000 - 0xBFFF_FFFF |
 * |----|-------|-----------------------|---------------------------|
 * |24	| 11000	| Slot 0 Memory Area	| 0xC000_0000 - 0xC7FF_FFFF |
 * |25	| 11001	| Slot 1 Memory Area	| 0xC800_0000 - 0xCFFF_FFFF |
 * |26	| 11010	| Slot 2 Memory Area	| 0xD000_0000 - 0xD7FF_FFFF |
 * |27	| 11011	| Slot 3 Memory Area	| 0xD800_0000 - 0xDFFF_FFFF |
 * |28	| 11100	| Slot 4 Memory Area	| 0xE000_0000 - 0xE7FF_FFFF |
 * |29	| 11101	| Slot 5 Memory Area	| 0xE800_0000 - 0xEFFF_FFFF |
 * |30	| 11110	| Slot 6 Memory Area	| 0xF000_0000 - 0xF7FF_FFFF |
 * |31	| 11111	| Slot 7 Memory Area	| 0xF800_0000 - 0xFFFF_FFFF |
 *
*/

MEMORY {
	sram	(rwx)	: ORIGIN = sram_bot, LENGTH = 512K
	rom	(rx)	: ORIGIN = rom_bot,  LENGTH = 4M
}

SECTIONS {
	.text : {
		KEEP(*(.vectors .vectors.*))
		*(.text*)
		*(.rodata*)
	} > rom

	.bss (NOLOAD) : {
		*(.bss*)
		*(COMMON)
	} > sram

	.data : {
		*(.data*);
	} > sram AT >rom

	_end = .;
}
