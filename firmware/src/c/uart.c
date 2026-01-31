#include <stdint.h>
#include "uart68681.h"
#include "ring_buffer.h"
#include "stringlib.h"

extern int printf_(const char *fmt, ...);

/* Because we don't have kernel.h */
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

enum { bufsiz = 256 };

static volatile unsigned char txbuf[bufsiz];
volatile int tx_write_indx, tx_read_indx;

static rbd_t _rxbd;
static char _rxbuf[8];
//static rbd_t _txbd;
//static char _txbuf[8];

void init_uart(void) {
	// A
	uart->cra  = 0x20;	// reset receiver
	uart->cra  = 0x30;	// reset transmitter
	uart->cra  = 0x40;	// reset error status
	uart->cra  = 0x10;	// reset mode register pointer
	uart->csra = 0x66;	// 1200bps XMIT and RCV
	uart->mr1a = 0x13;	// no parity, 8 bits/char
	uart->mr2a = 0x07;	// 1 stop bit
	uart->cra  = 0x05;  // enable XMIT and RCV

	// B
	uart->crb  = 0x20;	// reset receiver
	uart->crb  = 0x30;	// reset transmitter
	uart->crb  = 0x40;	// reset error status
	uart->crb  = 0x10;	// reset mode register pointer
	uart->csrb = 0x66;	// 1200bps XMIT and RCV
	uart->mr1b = 0x13;	// no parity, 8 bits/char
	uart->mr2b = 0x07;	// 1 stop bit
	uart->crb  = 0x05;  // enable XMIT and RCV
}

/*
static void uart_flush_rx(void) {
	// drain any pending characters
	for (;;) {
		uint8_t s = uart->sra;
		if (!(s & 0x01)) {
			break;
		}
		(void)uart->rba;
	}
}
*/

void init_uartbuf(void) {
	uart->imr = 0;
	return;

	tx_write_indx = 0;
	tx_read_indx = 0;
	
	rb_attr_t attr_rx = {sizeof(_rxbuf[0]), ARRAY_SIZE(_rxbuf), _rxbuf};
	//rb_attr_t attr_tx = {sizeof(_txbuf[0]), ARRAY_SIZE(_txbuf), _txbuf};
	ring_buffer_init(&_rxbd, &attr_rx);
	//ring_buffer_init(&_txbuf, &attr_tx);
	return;
}

void _putchar(unsigned char c) {
	uint8_t status_val;
	do {
		status_val = uart->sra;
	}
    	while (!(status_val & (1 << 2))); // Polling

	uart->tba = c;
	return;
}

char _getchar(void) {
	for (;;) {
		uint8_t s = uart->sra;

		if (s & 0x01) {			// RXRDY
			char c = uart->rba;	// latch data
			//printf_("\r\n[debug _getchar] SRA=0x%02X, c=0x%02X '%c'\r\n", s, (unsigned char)c, (c >= 32 && c <= 126) ? c : '.');

			// If framing error, parity error, overrun error
			/*
			if (s & 0x70) {
				// Optional log
				//printf_("UART error, SRA=0x%02X\r\n", s);
				// discard and keep waiting
				continue;
			}
			*/

			return c;
		}
	}
}

void __attribute__((interrupt)) uart_isr() {

	// If Ch.B Receiver Ready:
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
