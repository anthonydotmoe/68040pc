#include <stdint.h>
#include "uart68681.h"

enum { bufsiz = 256 };

static volatile unsigned char txbuf[bufsiz];
static volatile unsigned char rxbuf[bufsiz];
volatile int tx_write_indx, tx_read_indx, rx_write_indx, rx_read_indx;

void init_uartbuf(void) {
	tx_write_indx = 0;
	tx_read_indx = 0;
	rx_write_indx = 0;
	rx_read_indx = 0;
	return;
}

/*
 * Interrupts should be enabled for:
 * 	- Channel A Receiver Ready (SRA[0]) (reset MR1A[6])
 * 		- Always
 * 	- Channel A Transmitter Ready
 * 		- When the cirqueue has more than 0 elements in it
 *
 */

void _putchar(unsigned char c) {
	while ((tx_write_indx + 1) % bufsiz == tx_read_indx); // Buffer is full, hang around and wait

	// Critical section
	asm volatile(
			"movew  %%sr,%-;"
			"orw    #0x700,%%sr;"
			: : :);

	// If the buffer is empty, we enable the transmit-ready interrupt
	if (tx_read_indx == tx_write_indx) {
		uart->imr = 0b11; // set Transmitter A ready interrupt
	}

	txbuf[tx_write_indx] = c;
	tx_write_indx = (tx_write_indx + 1) % bufsiz;

	// End critical section
	asm ("movew  %+,%%sr": : :);
	return;
}

int _getchar(void) {
	int ch = 0;
	while (rx_read_indx == rx_write_indx); // Buffer is empty, hang around and wait

	// Critical section
	asm volatile(
			"movew  %%sr,%-;"
			"orw    #0x700,%%sr;"
			: : :);


	// Get character from the buffer and increment pointer
	ch = (int)rxbuf[rx_read_indx];
	rx_read_indx = (rx_read_indx + 1) % bufsiz;

	
	// End critical section
	asm ("movew  %+,%%sr": : :);
	return ch;
}


void __attribute__((interrupt)) uart_isr() {

	// If Ch.A Receiver Ready:
	if (uart->sra & 0x01) {
		// Place the received character in the recv cirqueue
		rxbuf[rx_write_indx] = uart->rba;
		rx_write_indx = (rx_write_indx + 1) % bufsiz;
		return;
	}

	// If the buffer is empty, disable the interrupt
	if (tx_read_indx == tx_write_indx) {
		// buffer is empty
		uart->imr = 0b10; // clear Transmitter A ready interrupt
		return;
	}

	uart->tba = txbuf[tx_read_indx];
	tx_read_indx = (tx_read_indx + 1) % bufsiz;
	return;
}

