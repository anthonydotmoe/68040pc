#pragma once

static inline void irq_disable(void)
{
    asm volatile ("oriw  #0x0700,%%sr" : : : "cc", "memory");
}

static inline void irq_enable(void)
{
    asm volatile ("andiw %0,%%sr" : : "i" (-0x700) : "memory");
}

static inline unsigned long save_flags(void)
{
    unsigned long flags;
    asm volatile ("movew %%sr,%0" : "=d" (flags) : : "memory");
    return flags;
}

static inline void restore_flags(unsigned long flags)
{
    asm volatile ("movew %0,%%sr" : : "d" (flags) : "memory");
}

static inline void die(void)
{
    asm volatile ("stop #0x2700" : : : "cc", "memory");
}
