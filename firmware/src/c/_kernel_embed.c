#include <stdint.h>
#include "romimage.h"

#ifndef KERNEL_FILEPATH
#error  "Need to define KERNEL_FILEPATH"
#endif

/* Payload bytes */
__attribute__((section(".kernel_romimage.payload"), aligned(8)))
const unsigned char kernel_elf_payload[] = {
    #embed KERNEL_FILEPATH
};

/* Header */
__attribute__((section(".kernel_romimage.header"), aligned(8)))
const romimage_t kernel_elf_header = {
    .magic      = 0x55AA0E1F,
    .size       = (uint32_t)sizeof(kernel_elf_payload),
    .reserved_0 = 0,
    .reserved_1 = 0,
};
