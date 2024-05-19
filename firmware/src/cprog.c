#include "uart.h"
#include <stdint.h>

extern int printf_(const char* format, ...);

void c_prog_entry(void) {
	int c;

	printf_("We made it to C!\r\n");
	
	c = _getchar();
	printf_("Got '%c'\r\n",c);

	return;
}
