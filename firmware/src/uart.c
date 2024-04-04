#include <stdint.h>
#include "uart68681.h"

enum { bufsiz = 256 };

static unsigned char txbuf[bufsiz];
int write_indx;
int read_indx;

void init_txbuf(void) {
	write_indx = 0;
	read_indx = 0;
	return;
}

void _putchar(unsigned char c) {
    while ((write_indx + 1) % bufsiz == read_indx); // Buffer is full, hang around and wait

    // Critical section
    asm volatile(
		    "movew  %%sr,%-;"
		    "orw    #0x700,%%sr;"
    : : :);

    // If the buffer is empty, we enable the transmit-ready interrupt
    if (read_indx == write_indx) {
        uart->imr = 0x01; // set Transmitter A ready interrupt
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
        uart->imr = 0x00; // clear interrupts
        return;
    }

    uart->tba = txbuf[read_indx];
    read_indx = (read_indx + 1) % bufsiz;
    return;
}

