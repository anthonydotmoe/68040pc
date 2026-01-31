#pragma once
#include <stddef.h>

/*
 * simple bump allocator for early boot / firmware use
 *
 * Contract:
 * - Returns a pointer to a region of at least `len` bytes
 * - The returned pointer is aligned to ALLOC_ALIGNMENT bytes
 * - Returns NULL on failure (out of space, overflow, len==0, etc.)
 */
void* alloc(size_t len);
#define ALLOC_ALIGNMENT 4u
