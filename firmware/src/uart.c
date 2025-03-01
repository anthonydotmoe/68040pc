#include <stdint.h>
#include <string.h>
#include "uart68681.h"
#include "ring_buffer.h"
#include "memcpy.h"

/* Because we don't have kernel.h */
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

enum { bufsiz = 256 };

static volatile unsigned char txbuf[bufsiz];
volatile int tx_write_indx, tx_read_indx;

static rbd_t _rxbd;
static char _rxbuf[8];
//static rbd_t _txbd;
//static char _txbuf[8];

void init_uartbuf(void) {
	tx_write_indx = 0;
	tx_read_indx = 0;
	
	rb_attr_t attr_rx = {sizeof(_rxbuf[0]), ARRAY_SIZE(_rxbuf), _rxbuf};
	//rb_attr_t attr_tx = {sizeof(_txbuf[0]), ARRAY_SIZE(_txbuf), _txbuf};
	ring_buffer_init(&_rxbd, &attr_rx);
	//ring_buffer_init(&_txbuf, &attr_tx);
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

int uart_getchar(void) {
	char c = -1;

	ring_buffer_get(_rxbd, &c);

	return c;
}

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
	char c = -1;
	
	ring_buffer_get(_rxbd, &c);
	
	return c;
}

void __attribute__((interrupt)) uart_isr() {

	// If Ch.A Receiver Ready:
	if (uart->sra & 0x01) {
		const char c = uart->rba;
		ring_buffer_put(_rxbd, &c);
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

