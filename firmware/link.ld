OUTPUT_FORMAT("binary")

rom_bot		= 0x00000000;
rom_top		= 0x001FFFFF;

sram_bot	= 0x30000400;	/* With room for vectors */
sram_top	= 0x3007FFFF;

stack_top	= sram_top + 1;

MEMORY {
	sram	(rwx)	: ORIGIN = sram_bot, LENGTH = 512K
	rom	(rx)	: ORIGIN = rom_bot,  LENGTH = 2M
}

SECTIONS {
	.text : {
		KEEP(*(.vectors .vectors.*));
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
