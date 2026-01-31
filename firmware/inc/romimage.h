#pragma once
#include <stdint.h>

// In-memory ROM file object header
typedef struct _romimage_t {
    uint32_t magic;     // 0x55AA0E1F
    uint32_t size;
    uint32_t reserved_0;
    uint32_t reserved_1;
    // uint8_t  data[];
} romimage_t;
