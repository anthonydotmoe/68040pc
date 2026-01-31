#pragma once

#include <stdint.h>

struct bi_record {
    uint16_t tag;       // tag ID
    uint16_t size;      // size of record (in bytes)
    uint32_t data[];    // data
};

struct mem_info {
    uint32_t addr;      // physical address of memory chunk
    uint32_t size;      // length of memory chunk (in bytes)
};

#define BI_LAST         0x0000  // list record (sentinel)
#define BI_MACHTYPE     0x0001  // machine type
#define BI_CPUTYPE      0x0002  // cpu type
#define BI_FPUTYPE      0x0003  // fpu type
#define BI_MMUTYPE      0x0004  // mmu type
#define BI_MEMCHUNK     0x0005  //memory chunk address and size
                                // (struct mem_info)
#define BI_RAMDISK      0x0006  // ramdisk address and size
                                // (struct mem_info)
#define BI_COMMAND_LINE 0x0007  // kernel command line parameters
                                // (string)

// A random seed used to initialize the RNG:
// - length    [2 bytes, 16-bit big endian]
// - seed data [`length` bytes, padded to preserve 4-byte struct alignment]
#define BI_RNG_SEED     0x0008

/* Linux/m68k Architectures (BI_MACHTYPE) */
#define MACH_AMIGA      1
#define MACH_ATARI      2
#define MACH_MAC        3
#define MACH_APOLLO     4
#define MACH_SUN3       5
#define MACH_MVME147    6
#define MACH_MVME16x    7
#define MACH_BVME6000   8
#define MACH_HP300      9
#define MACH_Q40        10
#define MACH_SUN3X      11
#define MACH_M54XX      12
#define MACH_M5441X     13
#define MACH_VIRT       14
#define MACH_A68040PC   15

/* CPU, FPU, MMU types (BI_CPUTYPE, BI_FPUTYPE, BI_MMUTYPE) */

#define CPUB_68020      0
#define CPUB_68030      1
#define CPUB_68040      2
#define CPUB_68060      3
#define CPUB_COLDFIRE   4

#define CPU_68020       (1 << CPUB_68020)
#define CPU_68030       (1 << CPUB_68030)
#define CPU_68040       (1 << CPUB_68040)
#define CPU_68060       (1 << CPUB_68060)
#define CPU_COLDFIRE    (1 << CPUB_COLDFIRE)

#define FPUB_68881      0
#define FPUB_68882      1
#define FPUB_68040      2   /* Internal FPU */
#define FPUB_68060      3   /* Internal FPU */
#define FPUB_SUNFPA     4   /* Sun-3 FPA */
#define FPUB_COLDFIRE   5   /* ColdFire FPU */

#define FPU_68881       (1 << FPUB_68881)
#define FPU_68882       (1 << FPUB_68882)
#define FPU_68040       (1 << FPUB_68040)
#define FPU_68060       (1 << FPUB_68060)
#define FPU_SUNFPA      (1 << FPUB_SUNFPA)
#define FPU_COLDFIRE    (1 << FPUB_COLDFIRE)

#define MMUB_68851      0
#define MMUB_68030      1   /* Internal MMU */
#define MMUB_68040      2   /* Internal MMU */
#define MMUB_68060      3   /* Internal MMU */
#define MMUB_APOLLO     4   /* Custom Apollo */
#define MMUB_SUN3       5   /* Custom Sun-3 */
#define MMUB_COLDFIRE   6   /* Internal MMU */

#define MMU_68851       (1 << MMUB_68851)
#define MMU_68030       (1 << MMUB_68030)
#define MMU_68040       (1 << MMUB_68040)
#define MMU_68060       (1 << MMUB_68060)
#define MMU_SUN3        (1 << MMUB_SUN3)
#define MMU_APOLLO      (1 << MMUB_APOLLO)
#define MMU_COLDFIRE    (1 << MMUB_COLDFIRE)

#define BOOTINFOV_MAGIC             0x4249561A  /* 'BIV^Z' */
#define MK_BI_VERSION(major,minor)  (((major) << 16) + (minor))
#define BI_VERSION_MAJOR(v)         (((v) >> 16) & 0xffff)
#define BI_VERSION_MINOR(v)         ((v) >> & 0xffff)

struct __attribute__((packed)) bootversion {
    uint16_t branch;
    uint32_t magic;
    struct {
        uint32_t machtype;
        uint32_t version;
    } machversions[];
};
