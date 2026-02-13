#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>
#include <inttypes.h>
#include <elf.h>

#include "alloc.h"
#include "stringlib.h"
#include "bootparams.h"
#include "bootparams_a68040pc.h"
#include "loader.h"
#include "romimage.h"
#include "uart68681.h"  // for base address

#include "asm/irq.h"
#include "asm/movec.h"

#define printf printf_
extern int printf_(const char* format, ...);

// Debug prints
#define dprintf printf_

#define MAX_BP_SIZE     (1024)
#define NUM_MEMINFO     (1)
#define CL_SIZE         (256)
#define TEMP_STACKSIZE  (256)

struct my_bootparams {
    uint32_t machtype;
    uint32_t cputype;
    uint32_t fputype;
    uint32_t mmutype;
    uint32_t duartbase;
    int num_memory;
    struct mem_info memory[NUM_MEMINFO];
    struct user_image user_image;
    char command_line[CL_SIZE];
};

union _bp_union {
    struct bp_record record;
    uint8_t fake[MAX_BP_SIZE];
};

static struct my_bootparams bi;
static union _bp_union bp_union;
static unsigned long bp_size;

extern const unsigned char __userimage_romimage_start[]; // symbol from linker script

static int load_user_image_segments(void)
{
    const romimage_t *img = (const romimage_t *)(uintptr_t)__userimage_romimage_start;
    const uint32_t ROMIMAGE_MAGIC = 0x55AA0E1Fu;

    if (img->magic != ROMIMAGE_MAGIC) {
        printf("Invalid user image header magic: 0x%08" PRIx32 "\r\n", img->magic);
        return 0;
    }

    const uint8_t *elf_src = (const uint8_t *)img + sizeof(*img);
    const uint32_t elf_size = img->size;

    if (elf_size < sizeof(Elf32_Ehdr)) {
        printf("User image too small to be ELF\r\n");
        return 0;
    }

    const Elf32_Ehdr *eh = (const Elf32_Ehdr *)(const void *)elf_src;
    if (memcmp(eh->e_ident, ELFMAG, SELFMAG) != 0 ||
        eh->e_ident[EI_CLASS] != ELFCLASS32 ||
        eh->e_ident[EI_DATA]  != ELFDATA2MSB ||
        eh->e_type != ET_EXEC ||
        eh->e_machine != EM_68K ||
        eh->e_version != EV_CURRENT) {
        printf("User image ELF header invalid\r\n");
        return 0;
    }

    if (eh->e_phentsize != sizeof(Elf32_Phdr) || eh->e_phnum == 0) {
        printf("User image has invalid phdr table\r\n");
        return 0;
    }
    if (eh->e_phoff > elf_size ||
        (uint32_t)eh->e_phnum > (elf_size - eh->e_phoff) / sizeof(Elf32_Phdr)) {
        printf("User image phdr table out of range\r\n");
        return 0;
    }

    const Elf32_Phdr *ph = (const Elf32_Phdr *)(const void *)(elf_src + eh->e_phoff);

    // Find virtual span of all PT_LOAD segments
    uint32_t min_vaddr = 0xffffffffu;
    uint32_t max_vaddr = 0;

    for (uint16_t i = 0; i < eh->e_phnum; i++) {
        if (ph[i].p_type != PT_LOAD || ph[i].p_memsz == 0) {
            continue;
        }
        if (ph[i].p_filesz > ph[i].p_memsz) {
            printf("PT_LOAD has filesz > memsz\r\n");
            return 0;
        }
        if (ph[i].p_offset > elf_size || ph[i].p_filesz > (elf_size - ph[i].p_offset)) {
            printf("PT_LOAD data out of range\r\n");
            return 0;
        }
        if (ph[i].p_vaddr < min_vaddr) {
            min_vaddr = ph[i].p_vaddr;
        }
        uint32_t seg_end = ph[i].p_vaddr + ph[i].p_memsz;
        if (seg_end > max_vaddr) {
            max_vaddr = seg_end;
        }
    }

    if (min_vaddr == 0xffffffffu) {
        printf("User image has no loadable segments\r\n");
        return 0;
    }

    // Optional: align span to a page (or at least 4/16). Use your page size.
    const uint32_t PAGE = 0x1000;
    uint32_t span = max_vaddr - min_vaddr;
    uint32_t span_rounded = (span + PAGE - 1) & ~(PAGE - 1);

    uint8_t *blob = (uint8_t *)alloc(span_rounded);
    if (!blob) {
        printf("Unable to allocate user image span: 0x%08" PRIx32 "\r\n", span_rounded);
        return 0;
    }
    // Zero whole blob so gaps between segments become zero-filled.
    memset(blob, 0, span_rounded);

    // Load each PT_LOAD into the blob at (vaddr - min_vaddr)
    for (uint16_t i = 0; i < eh->e_phnum; i++) {
        if (ph[i].p_type != PT_LOAD || ph[i].p_memsz == 0) {
            continue;
        }

        uint32_t off = ph[i].p_vaddr - min_vaddr;
        if (off > span_rounded || ph[i].p_memsz > (span_rounded - off)) {
            printf("PT_LOAD does not fit in allocated span\r\n");
            return 0;
        }

        uint8_t *dst = blob + off;
        const uint8_t *src = elf_src + ph[i].p_offset;

        memcpy(dst, src, ph[i].p_filesz);
        // bss tail already zero because we memset(blob,0,span_rounded)
        // but it doesn't hurt to be explicit:
        // memset(dst + ph[i].p_filesz, 0, ph[i].p_memsz - ph[i].p_filesz);
    }

    bi.user_image.addr  = (uint32_t)(uintptr_t)blob;       // physical address from alloc()
    bi.user_image.size  = span_rounded;
    bi.user_image.vaddr = min_vaddr;
    bi.user_image.entry = eh->e_entry;

    dprintf("User image loaded:\r\n  paddr: 0x%08" PRIx32 "\r\n  size: 0x%08" PRIx32
            "\r\n  vbase: 0x%08" PRIx32 "\r\n  entry: 0x%08" PRIx32 "\r\n",
            bi.user_image.addr, bi.user_image.size, bi.user_image.vaddr, bi.user_image.entry);

    return 1;
}

static int add_bp_record(uint16_t tag, uint16_t size, const void* data)
{
    struct bp_record* record;
    uint16_t size2;

    size2 = (sizeof(struct bp_record) + size + 3) & -4;
    if (bp_size + size2 + sizeof(bp_union.record.tag) > MAX_BP_SIZE) {
        printf("Failed to add bootparams record, MAX_BP_SIZE too small!\r\n");
        return 0;
    }
    record = (struct bp_record*)((uint32_t)&bp_union.record + bp_size);
    record->tag = tag;
    record->size = size2;
    memcpy(record->data, data, size);
    bp_size += size2;
    return 1;
}

static int add_bp_string(uint16_t tag, const char* s)
{
    return add_bp_record(tag, strlen(s) + 1, (void*)s);
}

static int init_bootparams()
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

    if (!load_user_image_segments()) {
        return 0;
    }

    // Assemble bootparams structure
    struct bp_record* record;

    // Init
    bp_size = 0;

    if (!add_bp_record(BP_MACHTYPE, sizeof(bi.machtype), &bi.machtype))
        return 0;
    if (!add_bp_record(BP_CPUTYPE,  sizeof(bi.cputype),  &bi.cputype))
        return 0;
    if (!add_bp_record(BP_FPUTYPE,  sizeof(bi.fputype),  &bi.fputype))
        return 0;
    if (!add_bp_record(BP_MMUTYPE,  sizeof(bi.mmutype),  &bi.mmutype))
        return 0;
        // fputype used because it has 0 in it
    if (!add_bp_record(BP_A68040PC_VERSION,  sizeof(bi.fputype),  &bi.fputype))
        return 0;
    if (!add_bp_record(BP_A68040PC_DUARTBASE,  sizeof(bi.duartbase),  &bi.duartbase))
        return 0;
    for (int i = 0; i < bi.num_memory; i++) {
        if (!add_bp_record(BP_MEMCHUNK, sizeof(bi.memory[i]),  &bi.memory[i]))
            return 0;
    }
    if (!add_bp_string(BP_COMMAND_LINE, bi.command_line))
        return 0;
    
    if (!add_bp_record(BP_USERIMAGE, sizeof(bi.user_image), &bi.user_image))
        return 0;
    
    // Trailer
    record = (struct bp_record*)((uint32_t)&bp_union.record + bp_size);
    record->tag = BP_LAST;
    record->size = 4;
    bp_size += 4;

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

    if (!init_bootparams()) {
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

    // Allocate memory for the initial copy of the kernel image + bootparams
    uint32_t needed = info.image_size + bp_size;
    printf("Allocating 0x%.8"PRIx32" for the kernel\r\n", needed);
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

    // Append bootparams after the loaded image region
    void* bp_dst = (uint8_t*)kernel_dest + info.image_size;
    memcpy(bp_dst, &bp_union, bp_size);

    dprintf("bootparams loaded at 0x%.8"PRIx32"\r\n", (uint32_t)bp_dst);

    dprintf("bootparams will be located at 0x%.8"PRIx32"\r\n",
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
