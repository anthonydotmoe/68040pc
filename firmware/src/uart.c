#include <stdint.h>
#include "uart68681.h"
#include "ring_buffer.h"
#include "memcpy.h"

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

/*
 * Interrupts should be enabled for:
 * 	- Channel A Receiver Ready (SRA[0]) (reset MR1A[6])
 * 		- Always
 * 	- Channel A Transmitter Ready
 * 		- When the cirqueue has more than 0 elements in it
 *
 */
void _putchar(unsigned char c) {

	// Slow polling method
	uint8_t status_val;
	do {
		status_val = uart->sra;
	}
    	while (!(status_val & (1 << 2))); // Polling

	uart->tba = c;
	return;


	/*
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
	*/
}

/*
int _getchar(void) {
	char c;
	
	// Slow polling method
	while ((uart->sra & (1 << 0)) == 0);
	c = uart->rba;
	return (int)c & 0xFF;
}
*/

int _getchar(void) {
    uint8_t status_val;
    
    // Wait for RX Ready
    do {
	    status_val = uart->sra;
    }
    while (!(status_val & (1 << 0))); // polling
    
    // Read the character
    char c = uart->rba;

    // Print status value
    printf_("status before: 0x%02x\n", status_val);

    // Read status
    status_val = uart->sra;

    // Print status value
    printf_("status after: 0x%02x\n", status_val);
 
    // Check error bits (Overrun=bit1, Parity=bit2, Framing=bit3)
    // If any error is set, read the data register again to clear it.
    /*
    if (((status_val & 0x70) & (status_val & 0x01)) != 0) {
	printf_("error? uart->sra: 0x%x\n", status_val);
    }
    */
    
    return (int) (c & 0xFF);
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

