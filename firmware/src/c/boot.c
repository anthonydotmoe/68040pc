#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>
#include <inttypes.h>

#include "alloc.h"
#include "stringlib.h"
#include "bootinfo.h"
#include "bootinfo-a68040pc.h"
#include "loader.h"
#include "uart68681.h"  // for base address

#include "asm/irq.h"
#include "asm/movec.h"

#define printf printf_
extern int printf_(const char* format, ...);

// Debug prints
#define dprintf printf_

#define MAX_BI_SIZE     (1024)
#define NUM_MEMINFO     (1)
#define CL_SIZE         (256)
#define TEMP_STACKSIZE  (256)

struct my_bootinfo {
    uint32_t machtype;
    uint32_t cputype;
    uint32_t fputype;
    uint32_t mmutype;
    uint32_t duartbase;
    int num_memory;
    struct mem_info memory[NUM_MEMINFO];
    char command_line[CL_SIZE];
};

union _bi_union {
    struct bi_record record;
    uint8_t fake[MAX_BI_SIZE];
};

static struct my_bootinfo bi;
static union _bi_union bi_union;
static unsigned long bi_size;

static int add_bi_record(uint16_t tag, uint16_t size, const void* data)
{
    struct bi_record* record;
    uint16_t size2;

    size2 = (sizeof(struct bi_record) + size + 3) & -4;
    if (bi_size + size2 + sizeof(bi_union.record.tag) > MAX_BI_SIZE) {
        printf("Failed to add bootinfo record, MAX_BI_SIZE too small!\r\n");
        return 0;
    }
    record = (struct bi_record*)((uint32_t)&bi_union.record + bi_size);
    record->tag = tag;
    record->size = size2;
    memcpy(record->data, data, size);
    bi_size += size2;
    return 1;
}

static int add_bi_string(uint16_t tag, const char* s)
{
    return add_bi_record(tag, strlen(s) + 1, (void*)s);
}

static int init_bootinfo()
{
    bi.machtype     = MACH_A68040PC;
    bi.cputype      = CPU_68040;
    bi.fputype      = 0;
    bi.mmutype      = MMU_68040;
    bi.duartbase    = UART_BASE;

    const char cmdline[] = "boot_delay=1000";
    memcpy(bi.command_line, cmdline, sizeof(cmdline) + 1);

    // TODO: Do memory detection and propogate the results here:
    uint32_t addr = 0x40000000;
    uint32_t size = 0x00100000;

    bi.num_memory   = 0;
    if (bi.num_memory < NUM_MEMINFO) {
        bi.memory[bi.num_memory].addr = addr;
        bi.memory[bi.num_memory].size = size;
        bi.num_memory++;
    }

    // Assemble bootinfo structure
    struct bi_record* record;

    // Init
    bi_size = 0;

    if (!add_bi_record(BI_MACHTYPE, sizeof(bi.machtype), &bi.machtype))
        return 0;
    if (!add_bi_record(BI_CPUTYPE,  sizeof(bi.cputype),  &bi.cputype))
        return 0;
    if (!add_bi_record(BI_FPUTYPE,  sizeof(bi.fputype),  &bi.fputype))
        return 0;
    if (!add_bi_record(BI_MMUTYPE,  sizeof(bi.mmutype),  &bi.mmutype))
        return 0;
        // fputype used because it has 0 in it
    if (!add_bi_record(BI_A68040PC_VERSION,  sizeof(bi.fputype),  &bi.fputype))
        return 0;
    if (!add_bi_record(BI_A68040PC_DUARTBASE,  sizeof(bi.duartbase),  &bi.duartbase))
        return 0;
    for (int i = 0; i < bi.num_memory; i++) {
        if (!add_bi_record(BI_MEMCHUNK, sizeof(bi.memory[i]),  &bi.memory[i]))
            return 0;
    }
    if (!add_bi_string(BI_COMMAND_LINE, bi.command_line))
        return 0;
    
    // Trailer
    record = (struct bi_record*)((uint32_t)&bi_union.record + bi_size);
    record->tag = BI_LAST;
    bi_size += sizeof(bi_union.record.tag);

    return 1;
}

/*
 * Swtiches stack pointer to `stack_top`
 * Assembles arguments for `trampoline_func`
 * Jumps to `trampoline_func`
 */
__attribute__((noreturn))
static void start_kernel(uintptr_t trampoline_func,
                         uintptr_t entry_addr,
                         void* image_dest,
                         void* image_src,
                         size_t image_size,
                         void *stack_top)
{
    asm volatile (
        "move.l %0,%%a0\n\t"
        "move.l %5,%%sp\n\t"
        "move.l %1,%%sp@-\n\t"  // entry
        "move.l %2,%%sp@-\n\t"  // dst
        "move.l %3,%%sp@-\n\t"  // src
        "move.l %4,%%sp@-\n\t"  // size
        "jmp    (%%a0)\n\t"
        :
        : "r"(trampoline_func), "r"(entry_addr), "r"(image_dest), "r"(image_src), "r"(image_size), "r"(stack_top)
        : "a0", "memory", "cc"
    );

    __builtin_unreachable();
}

extern const unsigned char __kernel_romimage_start[]; // symbol from linker script
// Eventually this will be a user saved string, or NVMEM option, but for now,
// just build the boot string at runtime.
static void build_default_boot_string(char* spec)
{
    uint32_t addr = (uint32_t)(uintptr_t)__kernel_romimage_start;
    char *p = spec;

    // write "romimage:0x"
    *p++='r';
    *p++='o';
    *p++='m';
    *p++='i';
    *p++='m';
    *p++='a';
    *p++='g';
    *p++='e';
    *p++=':';
    *p++='0';
    *p++='x';

    // append 8 hex digits
    for (int i = 7; i >= 0; i--) {
        uint8_t nyb = (addr >> (i*4)) & 0xF;
        *p++ = (nyb < 10) ? ('0' + nyb) : ('A' + (nyb - 10));
    }
    *p = '\0';
}

// From copyandgo.s
extern const unsigned char copyandgo;
extern const unsigned char copyandgo_end;

/*---------------------------------------------------------------------------
 *  Entry
 *---------------------------------------------------------------------------*/

void c_prog_entry(void)
{
    kernel_image_info_t info;
    void* kernel_final_dest;
    void* kernel_dest;

    if (!init_bootinfo()) {
        goto Fail;
    }

    char spec[32];
    build_default_boot_string(spec);

    printf("Opening kernel from: \"%s\"\r\n", spec);

    if (!open_kernel(spec, &info)) {
        goto Fail;
    }

    // Decide final placement: map min_vaddr -> start_mem
    uintptr_t start_mem = bi.memory[0].addr;
    uint32_t  mem_size  = bi.memory[0].size;
    
    dprintf("Selected memory block:\r\n  addr: 0x%.8"PRIx32"\r\n  size: 0x%.8"PRIx32"\r\n",
            (uint32_t)start_mem,
            (uint32_t)mem_size);

    // TODO: Consider whether or not to reserve a page
    // For now: reserve 4K at bottom for safety
    //start_mem += PAGE_SIZE;
    //mem_size  -= PAGE_SIZE;

    // Allocate memory for the initial copy of the kernel image + bootinfo
    uint32_t needed = info.image_size + bi_size;
    kernel_dest = alloc(needed);
    if (!kernel_dest) {
        printf("Unable to allocate memory for the kernel: need 0x%.8"PRIx32"\r\n",
            (uint32_t)needed);
        goto Fail;
    }

    dprintf("Kernel load addr: 0x%.8"PRIx32"\r\n", (uint32_t)kernel_dest);

    kernel_final_dest = (uint8_t*)start_mem;
    printf("\r\nThe kernel will be located at 0x%.8"PRIx32"\r\n", (uint32_t)start_mem);

    // Load segments to the temporary buffer
    if (!load_kernel_to(kernel_dest, &info)) {
        goto Fail;
    }

    dprintf("Kernel loaded\r\n");

    // Append bootinfo after the loaded image region
    void* bi_dst = (uint8_t*)kernel_dest + info.image_size;
    memcpy(bi_dst, &bi_union, bi_size);

    dprintf("Bootinfo loaded at 0x%.8"PRIx32"\r\n", (uint32_t)bi_dst);

    dprintf("bootinfo will be located at 0x%.8"PRIx32"\r\n",
            (uint32_t)kernel_final_dest + (uint32_t)info.image_size);

    // Allocate temporary stack
    void *stack = alloc(TEMP_STACKSIZE);
    if (!stack) {
        printf("Unable to allocate memory for stack\r\n");
        goto Fail;
    }

    kernel_debug_info((uint32_t)kernel_final_dest, &info);

    // Allocate room for the copy-and-go routine
    size_t trampoline_size = &copyandgo_end - &copyandgo;
    void *trampoline = alloc(trampoline_size);
    if (!trampoline) {
        printf("Unable to allocate memory for startup code\r\n");
        goto Fail;
    }

    // Copy startup code to RAM
    memcpy(trampoline, &copyandgo, trampoline_size);
    uintptr_t trampoline_addr = (uintptr_t)trampoline;

    // Ooooh, it's happening!
    // Compute physical entry point and jump

    uintptr_t entry_addr =
        (uintptr_t)((uintptr_t)kernel_final_dest + (uintptr_t)(info.entry_vaddr - info.min_vaddr));
    
    // Temporary uint8_t* cast to allow for arithmetic
    void *stack_top = (uint8_t*)stack + TEMP_STACKSIZE;

    // Reset peripherals

    // Turn off caches

    // Turn off any MMU translation

    // Raise interrupt level
    irq_disable();
    
    // Switch VBR back to ROM
    //   The loader will clobber the current vector table. We'll use the ROM one
    //   in case we need a crash handler.
    set_vbr(0);

    dprintf("\r\nstart_kernel()\r\n  tramp_addr: 0x%.8"PRIx32"\r\n  entry_addr: 0x%.8"PRIx32"\r\n  kernel_dst: 0x%.8"PRIx32"\r\n  kernel_src: 0x%.8"PRIx32"\r\n  kernel_siz: 0x%.8"PRIx32"\r\n   stack_top: 0x%.8"PRIx32"\r\n",
        (uint32_t)trampoline_addr,
        (uint32_t)entry_addr,
        (uint32_t)kernel_final_dest,
        (uint32_t)kernel_dest,
        (uint32_t)needed,
        (uint32_t)stack_top);

    // Execute the kernel
    start_kernel(trampoline_addr, entry_addr, kernel_final_dest, kernel_dest, needed, stack_top);

Fail:

    while (1) {
        die();
    }

    return;
}
