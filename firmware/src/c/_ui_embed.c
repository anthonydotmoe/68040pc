#include <stdint.h>
#include "romimage.h"

#ifndef USERIMAGE_FILEPATH
#error  "Need to define USERIMAGE_FILEPATH"
#endif

/* Payload bytes */
__attribute__((section(".userimage_romimage.payload"), aligned(8)))
const unsigned char userimage_elf_payload[] = {
    #embed USERIMAGE_FILEPATH
};

/* Header */
__attribute__((section(".userimage_romimage.header"), aligned(8)))
const romimage_t userimage_elf_header = {
    .magic      = 0x55AA0E1F,
    .size       = (uint32_t)sizeof(userimage_elf_payload),
    .reserved_0 = 0,
    .reserved_1 = 0,
};
