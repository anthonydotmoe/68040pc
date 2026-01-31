#include <stddef.h>
#include <stdint.h>
#include <inttypes.h>
#include <elf.h>

#include "alloc.h"
#include "stringlib.h"
#include "loader.h"
#include "stream.h"

#define printf printf_
extern int printf_(const char* format, ...);

extern FS_MODULE romimage_fsmod;

static FS_MODULE* fs = &romimage_fsmod;

// header data of kernel executable
static Elf32_Ehdr kexec_elf;
static Elf32_Phdr *kernel_phdrs = NULL;

static bool read_exact(FS_MODULE* fs, void* buf, size_t n)
{
    ssize_t r = fs->read(buf, n);
    if (r < 0) return false;
    return (size_t)r == n;
}

int open_kernel(const char *kernel_name, kernel_image_info_t *out)
{
    fs->close(); // Init hack
    if (fs->open(kernel_name) < 0) {
        printf("Unable to get kernel image %s\r\n", kernel_name);
        return 0;
    }

    if (!read_exact(fs, &kexec_elf, sizeof(kexec_elf))) {
        printf("Cannot read ELF header of kernel image\r\n");
        return 0;
    }

    // Check ELF magic
    if (memcmp(&kexec_elf.e_ident[EI_MAG0], ELFMAG, SELFMAG) != 0) {
        printf("Kernel image is not an ELF executable\r\n");
        return 0;
    }

    if (kexec_elf.e_type    != ET_EXEC  ||
        kexec_elf.e_machine != EM_68K   ||
        kexec_elf.e_version != EV_CURRENT)
    {
        printf("Invalid ELF header contents in kernel\r\n");
        return 0;
    }

    size_t phdrs_siz = kexec_elf.e_phnum * sizeof(Elf32_Phdr);
    kernel_phdrs = (Elf32_Phdr*)alloc(phdrs_siz);
    if (!kernel_phdrs) {
        printf("Failed to allocate memory for PHDRS\r\n");
        return 0;
    }

    if (!fs->seek(kexec_elf.e_phoff, SEEK_SET)) {
        printf("Failed to seek to PHDRS in kernel image\r\n");
        return 0;
    }

    if (!read_exact(fs, kernel_phdrs, phdrs_siz)) {
        printf("Failed to read PHDRS from kernel image\r\n");
        return 0;
    }

    // Only consider PT_LOAD
    // Calculate the total required amount of memory
    uint32_t min_vaddr = 0xffffffffu;
    uint32_t max_vaddr = 0;

    for (int i = 0; i < kexec_elf.e_phnum; i++) {
        if (kernel_phdrs[i].p_type != PT_LOAD) continue;
        if (kernel_phdrs[i].p_memsz == 0) continue;
        if (kernel_phdrs[i].p_vaddr < min_vaddr)
            min_vaddr = kernel_phdrs[i].p_vaddr;
        
        uint32_t end = kernel_phdrs[i].p_vaddr + kernel_phdrs[i].p_memsz;
        if (end > max_vaddr)
            max_vaddr = end;
    }

    if (min_vaddr == 0xffffffffu) {
        printf("Kernel has no PT_LOAD segments\r\n");
        return 0;
    }

    // if (min_vaddr == 0) { // normalize }

    out->entry_vaddr = kexec_elf.e_entry;
    out->min_vaddr   = min_vaddr;
    out->max_vaddr   = max_vaddr;
    out->image_size  = max_vaddr - min_vaddr;
    out->phnum       = kexec_elf.e_phnum;

    return 1;
}

int load_kernel_to(void* dest_base, const kernel_image_info_t* info)
{
    // read the text and data segments from the kernel image
    for (int i = 0; i < kexec_elf.e_phnum; i++) {
        Elf32_Phdr *ph = &kernel_phdrs[i];
        if (ph->p_type != PT_LOAD) continue;
        if (ph->p_memsz == 0) continue;

        uint8_t* dest = (uint8_t*)dest_base + (ph->p_vaddr - info->min_vaddr);

        if (fs->seek(ph->p_offset, SEEK_SET) == -1) {
            printf("Failed to seek segment %d\r\n", i);
            return 0;
        }

        if (!read_exact(fs, dest, ph->p_filesz)) {
            printf("Failed to read segment %d\r\n", i);
            return 0;
        }

        // Zero BSS/tail: p_memz may be larger than p_filesz
        if (ph->p_memsz > ph->p_filesz) {
            memset(dest + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
        }
    }

    fs->close();
    return 1;
}

void kernel_debug_info(uint32_t phys_base, const kernel_image_info_t* info)
{
    for (int i = 0; i < kexec_elf.e_phnum; i++) {
        Elf32_Phdr *ph = &kernel_phdrs[i];
        if (ph->p_type != PT_LOAD) continue;
        if (ph->p_memsz == 0) continue;

        uint32_t seg_sys = phys_base + (ph->p_vaddr - info->min_vaddr);
        printf("PHDR %d (load at %#"PRIx32"):"
               " type=%#"PRIx32
               " off=%#"PRIx32
               " vaddr=%#"PRIx32
               " paddr=%#"PRIx32
               " filesz=%#"PRIx32
               " memsz=%#"PRIx32
               " flags=%#"PRIx32
               " align=%#"PRIx32"\r\n",
                   i,
                   seg_sys,
                   (uint32_t)ph->p_type,
                   (uint32_t)ph->p_offset,
                   (uint32_t)ph->p_vaddr,
                   (uint32_t)ph->p_paddr,
                   (uint32_t)ph->p_filesz,
                   (uint32_t)ph->p_memsz,
                   (uint32_t)ph->p_flags,
                   (uint32_t)ph->p_align);
        /*
        printf("Kernel PT_LOAD at %#lx, memsz %lu, filesz %lu\r\n",
            seg_sys, (unsigned long)ph->p_memsz, (unsigned long)ph->p_filesz);
        */
    }
}
