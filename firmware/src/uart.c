#include <stdint.h>
#include "uart68681.h"

enum { bufsiz = 256 };

static unsigned char txbuf[bufsiz];
static int write_indx = 0;
static int read_indx  = 0;

void putchar_(unsigned char c) {
    while ((write_indx + 1) % bufsiz == read_indx); // Buffer is full, hang around and wait

    // Critical section
    asm volatile(
		    "movew  %%sr,%-;"
		    "orw    #0x700,%%sr;"
    : : :);

    // If the buffer is empty, we enable the transmit-ready interrupt
    if (read_indx == write_indx) {
        uart->imr |= (1 << 0);
    }

    txbuf[write_indx] = c;
    write_indx = (write_indx + 1) % bufsiz;

    // End critical section
    asm ("movew  %+,%%sr": : :);
    return;
}

void __attribute__((interrupt)) uart_isr() {

    // If the buffer is empty, disable the interrupt
    if (read_indx == write_indx) {
        // buffer is empty
        uart->imr &= ~(1 << 0); // I would prefer a `bclr.b #0,5(a0)`
        return;
    }

    uart->tba = txbuf[read_indx];
    read_indx = (read_indx + 1) % bufsiz;
    return;
}

