#include <stdint.h>
#include <unistd.h>
#include <stddef.h>
#include <stdbool.h>

#include "romimage.h"
#include "stream.h"
#include "stringlib.h"

/* Prototypes */

static int romimage_open(const char *name);
static long romimage_fillbuf(void *buf);
static int romimage_skip(long cnt);
static int romimage_close(void);
static long romimage_filesize(void);

static ssize_t romimage_read(void *buf, size_t count);
static off_t romimage_seek(off_t offset, int whence);

// Helpers
static bool streq_prefix(const char *s, const char *prefix);
static bool parse_hex_u32(const char *s, uint32_t *out);

#define MAXBUF (4*1024)

MODULE romimage_mod = {
    "romimage",
    MAXBUF,
    romimage_open,
    romimage_fillbuf,
    romimage_skip,
    romimage_close,
    romimage_filesize,
    MOD_REST_INIT
};

FS_MODULE romimage_fsmod = {
    .name  = "romimage",
    .open  = romimage_open,
    .read  = romimage_read,
    .seek  = romimage_seek,
    .close = romimage_close,
};

static romimage_t* image_addr;

/* Internal file state */
static const uint8_t *romimage_base;
static size_t romimage_size;
static size_t romimage_pos;
static bool romimage_is_open = false;

static int romimage_open(const char *name) {
    const uint32_t ROMIMAGE_MAGIC = 0x55AA0E1Fu;
    const char *prefix = "romimage:";
    uint32_t addr_u32;

    // Must start with "romimage:"
    if (!streq_prefix(name, prefix)) return -1;
    name += 9; // strlen("romimage:")

    // Parse hex address after prefix
    if (!parse_hex_u32(name, &addr_u32)) return -1;

    image_addr = (romimage_t*)(uintptr_t)addr_u32;

    // Volatile read: treat ROM header as memory
    {
        volatile const romimage_t *hdr = (volatile const romimage_t*)image_addr;
        if (hdr->magic != ROMIMAGE_MAGIC)  {
            return -1;
        }

        /* Initialize file state */
        romimage_base = (const uint8_t *)(uintptr_t)((uintptr_t)image_addr + sizeof(romimage_t));
        romimage_size = (size_t)hdr->size;
        romimage_pos  = 0;
        romimage_is_open = true;
    }

    return 0;
}

static ssize_t romimage_read(void *buf, size_t count)
{
    size_t remaining;
    size_t to_copy;

    if (!romimage_is_open || romimage_base == NULL) return (ssize_t)-1;
    if (buf == NULL && count != 0) return (ssize_t)-1;

    if (romimage_pos >= romimage_size) {
        return 0; // EOF
    }

    remaining = romimage_size - romimage_pos;
    to_copy = (count < remaining) ? count : remaining;

    /* Read from ROM into caller buffer */
    memcpy(buf, romimage_base + romimage_pos, to_copy);
    romimage_pos += to_copy;

    return (ssize_t)to_copy;
}

static off_t romimage_seek(off_t offset, int whence)
{
    off_t base;
    off_t newpos;

    if (!romimage_is_open) return (off_t)-1;

    switch (whence) {
    case SEEK_SET:
        base = 0;
        break;
    case SEEK_CUR:
        base = (off_t)romimage_pos;
        break;
    case SEEK_END:
        base = (off_t)romimage_size;
        break;
    default:
        return (off_t)-1;
    }

    // Compute newpos with basic overflow safety
    newpos = base + offset;

    if (newpos < 0) return (off_t)-1;
    if ((size_t)newpos > romimage_size) return (off_t)-1;

    romimage_pos = (size_t)newpos;
    return newpos;
}

static long romimage_fillbuf(void *buf) {
    return (long)romimage_read(buf, MAXBUF);
}

static int romimage_skip(long cnt) {
    return (int)romimage_seek((off_t)cnt, SEEK_CUR);
}

static int romimage_close(void) {
    image_addr = (romimage_t*)0;
    romimage_base = (const uint8_t*)0;
    romimage_size = 0;
    romimage_pos = 0;
    romimage_is_open = false;
    return 0;
}

static long romimage_filesize(void) {
    if (romimage_is_open) {
        return (long)romimage_size;
    }
    else {
        return 0;
    }
}


// Helpers

static bool streq_prefix(const char *s, const char *prefix)
{
    if (!s || !prefix) return false;
    while (*prefix) {
        if (*s != *prefix) return false;
        ++s;
        ++prefix;
    }
    return true;
}

static bool hex_value(unsigned char c, uint32_t *out)
{
    if (c >= '0' && c <= '9') { *out = (uint32_t)(c - '0');       return true; }
    if (c >= 'a' && c <= 'f') { *out = (uint32_t)(c - 'a') + 10u; return true; }
    if (c >= 'A' && c <= 'F') { *out = (uint32_t)(c - 'A') + 10u; return true; }
    return false;
}

/* Parses one of:
   - "10000"
   - "0x10000" / "0X10000"
   Stops at first non-hex digit (after optional 0x), but requires at least one
   hex digit.
   Returns 1 on success and stores value in *out; else returns 0.
*/
static bool parse_hex_u32(const char *s, uint32_t *out)
{
    uint32_t v = 0;
    uint32_t digit = 0;
    int any = 0;

    if (!s || !out) return false;

    // Optional 0x / 0X
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
        s += 2;
    }

    while (*s) {
        if (!hex_value((unsigned char)*s, &digit)) break;
        any = 1;

        // v = v * 16 + digit; with overflow check
        if (v > (UINT32_MAX >> 4)) return false;    /* would overflow on shift */
        v <<= 4;
        if (v > (UINT32_MAX - digit)) return false; /* would overflow on add */
        v += digit;

        ++s;
    }

    if (!any) return false;
    *out = v;
    return true;
}
