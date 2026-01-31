#include <stddef.h>
#include <stdint.h>
#include <stdalign.h>

#include "alloc.h"

// Total bump-heap size
#define BUFSIZE_BYTES (256*1024u)

// Implementation detail:
// - We allocate from a uint32_t-backed array
// - This naturally provides >=4 byte alignment on sane ABIs
// - We also explicitly align the array to ALLOC_ALIGNMENT to make
//   the contract robust against any quirks.
#define WORD_SIZE_BYTES 4u

// Sanity checks
_Static_assert(ALLOC_ALIGNMENT != 0, "ALLOC_ALIGNMENT must be nonzero");
_Static_assert((ALLOC_ALIGNMENT & (ALLOC_ALIGNMENT - 1)) == 0, "ALLOC_ALIGNMENT must be a power of two");

// Backing store:
// - align to at least max_align_t so it's safe for any normal object type.
//   we could set it to `ALLOC_ALIGNMENT`, but max_align_t is stricter.
__attribute__((section(".heap")))
alignas(max_align_t) static unsigned char mem[BUFSIZE_BYTES];
static size_t bump = 0;

void* alloc(size_t len)
{
    if (len == 0) return NULL;

    // Round the current bump pointer up to ALLOC_ALIGNMENT
    size_t aligned_bump;
    if (bump > SIZE_MAX - (ALLOC_ALIGNMENT - 1)) return NULL;
    aligned_bump = (bump + (ALLOC_ALIGNMENT - 1)) & ~(size_t)(ALLOC_ALIGNMENT - 1) ;

    // Ensure aligned bump + len doesn't overflow and fits.
    if (len > SIZE_MAX - aligned_bump) return NULL;
    if (aligned_bump + len > BUFSIZE_BYTES) return NULL;

    void *out = (void*)(mem + aligned_bump);
    bump = aligned_bump + len;
    return out;
}
