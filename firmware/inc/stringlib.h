#pragma once

#include <stddef.h>

void *memcpy(void *dest, const void *src, size_t len);
int memcmp(const void *str1, const void *str2, size_t count);
size_t strlen(const char* s);
void* memset(void* s, int c, size_t n);
