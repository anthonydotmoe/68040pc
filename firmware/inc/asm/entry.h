#pragma once

typedef struct __attribute__((packed)) _exception_frame_t {
    // exception frame (format $0)
    unsigned short sr;
    unsigned long pc;
    unsigned short fmtvec; /* frame format / vector offset */
} exception_frame_t;

#define FMTVEC(format, vector_offset) \
    (unsigned short)((((format) & 0xF) << 12) | ((vector_offset) & 0x0FFF))

typedef struct __attribute__((packed)) _isr_trapframe_t {
    unsigned long d0;
    unsigned long d1;
    unsigned long d2;
    unsigned long d3;
    unsigned long d4;
    unsigned long d5;
    unsigned long d6;
    unsigned long d7;
    unsigned long a0;
    unsigned long a1;
    unsigned long a2;
    unsigned long a3;
    unsigned long a4;
    unsigned long a5;
    unsigned long a6;
    exception_frame_t frame;
} isr_trapframe_t;
