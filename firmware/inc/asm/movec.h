#pragma once

// Inline assembly routines to generate movec & related instructions

static inline void set_vbr(unsigned long vbr)
{
    asm volatile ("movec %0,%/vbr" : : "r"(vbr));
}

static inline unsigned long get_vbr(void)
{
    unsigned long vbr;
    asm volatile ("movec %/vbr,%0" : "=r"(vbr) : );
    return vbr;
}
