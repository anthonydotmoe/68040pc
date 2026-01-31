#include "stringlib.h"

size_t strlen(const char* s)
{
    const char *sc;

    for (sc = s; *sc != '\0'; ++sc) {}
    return sc - s;
}

void* memset(void* s, int c, size_t n)
{
    unsigned char* p = s;

    for (size_t i = 0; i < n; i++)
    {
        p[i] = (unsigned char)c;
    }

    return s;
}

int memcmp(const void *str1, const void *str2, size_t count)
{
    register const unsigned char *s1 = (const unsigned char*)str1;
    register const unsigned char *s2 = (const unsigned char*)str2;

    while (count-- > 0)
    {
        if (*s1++ != *s2++)
        {
            return s1[-1] < s2[-1] ? -1 : 1;
        }
    }
    return 0;
}

void *memcpy(void *dest, const void *src, size_t len) {
    char *d = dest;
    const char *s = src;
    while (len--)
        *d++ = *s++;
    return dest;
}
