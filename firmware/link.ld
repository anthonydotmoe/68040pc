OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_exc_ResetHandler)

/* Memory layout ------------------------------------------------------------ */

__rom_base = 0x00000000;
__rom_size = 2M;

__ram_base = 0x40000000;
__ram_size = 1M;

__stack_size = 4K;
__heap_size  = 256K;

__rom_end = __rom_base + __rom_size;
__ram_end = __ram_base + __ram_size;

MEMORY
{
    rom (rx)    : ORIGIN = __rom_base, LENGTH = __rom_size
    ram (rwx)   : ORIGIN = __ram_base, LENGTH = __ram_size
}

/* Sections ----------------------------------------------------------------- */

SECTIONS
{
    /* 680x0 exception vector table at 0x00000000 */
    .vectors __rom_base :
    {
        __vectors_start = .;
        KEEP(*(.vectors))
        . = ALIGN(4);
        __vectors_end = .;
    } > rom

    /* Code in ROM */
    .text :
    {
        __text_start = .;
        *(.text .text.*)
        . = ALIGN(4);
        __text_end = .;
    } > rom

    /* Embedded kernel image */
    .kernel_romimage ALIGN(8) :
    {
        __kernel_romimage_start = .;

        KEEP(*(.kernel_romimage.header))
        KEEP(*(.kernel_romimage.payload))

        __kernel_romimage_end = .;
    } > rom

    /* Read-only data in ROM */
    .rodata ALIGN(8) :
    {
        __rodata_start = .;
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
        . = ALIGN(4);
        __rodata_end = .;
    } > rom

    /* Initialized data in RAM, but load image sits right after .rodata */
    .data : AT(__rodata_end)
    {
        __data_start = .;
        *(.data .data.*)
        . = ALIGN(4);
        __data_end = .;
        ASSERT((__data_start % 4) == 0, "data start not 4-byte aligned");
        ASSERT((__data_end   % 4) == 0, "data end not 4-byte aligned");
        ASSERT((__data_load  % 4) == 0, "data load addr not 4-byte aligned");
    } > ram

    __data_load = LOADADDR(.data);

    /* Zero-init data in RAM */
    .bss (NOLOAD):
    {
        __bss_start = .;
        KEEP(*(.bss.vectors))
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
        ASSERT((__bss_start  % 4) == 0, "bss start not 4-byte aligned");
        ASSERT((__bss_end    % 4) == 0, "bss end not 4-byte aligned");
    } > ram

    /* Heap just below the stack (top of RAM)
       Uses NOLOAD to avoid ROM image size bloat */
    .heap (NOLOAD) :
    {
        __heap_start = ORIGIN(ram) + LENGTH(ram) - __stack_size - __heap_size;
        . = __heap_start;
        *(.heap .heap.*)
        __heap_end = __heap_start + __heap_size;
        . = __heap_end;
    } > ram

    /* Reserve stack space at the top of RAM
       (for bookkeeping, the CPU SSP comes from the vector table) */

    .stack :
    {
        __stack_bottom = ORIGIN(ram) + LENGTH(ram) - __stack_size;
        __stack_top_sym = ORIGIN(ram) + LENGTH(ram);
    } > ram

    /* Make a nicer name for C code */
    PROVIDE(__stack_top = __stack_top_sym);
}
