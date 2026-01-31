#pragma once
#include <stdint.h>
#include <stddef.h>

typedef struct _kernel_image_info_t {
    uint32_t entry_vaddr;       // e_entry from ELF
    uint32_t min_vaddr;         // min p_vaddr among PT_LOAD
    uint32_t max_vaddr;         // max(p_vaddr + p_memsz) among PT_LOAD
    uint32_t image_size;        // max_vaddr - min_vaddr
    uint16_t phnum;
} kernel_image_info_t;

#define PAGE_SIZE 4096

int open_kernel(const char *kernel_name, kernel_image_info_t* out);
int load_kernel_to(void* dest_base, const kernel_image_info_t* info);
void kernel_debug_info(uint32_t phys_base, const kernel_image_info_t* info);
