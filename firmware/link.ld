OUTPUT_FORMAT("binary")

rom_bot		= 0x00000000;
sram_bot	= 0x30000000;

MEMORY {
	sram	(rwx)	: ORIGIN = sram_bot, LENGTH = 1M
	rom	(rx)	: ORIGIN = rom_bot,  LENGTH = 2M
}

SECTIONS {
	.text : {
		KEEP(*(.vectors .vectors.*));
		*(.text*)
		*(.rodata*)
	} > rom

	.bss (NOLOAD) : {
		KEEP(*(.bss.vectors))
		*(.bss*)
		*(COMMON)
	} > sram

	.data : {
		*(.data*);
	} > sram AT >rom

	_end = .;
}
