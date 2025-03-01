const int CPU_68030 = 3;
const int CPU_68040 = 4;
const int CPU_68060 = 6;

unsigned long ckcpu346(void) {
	register unsigned long rv;
	unsigned long temp1, temp2, temp3;

	asm volatile (""
		"	| Register Usage:"
		"	| %0	return value"
		"	| %1	saved VBR"
		"	| %2	saved stack pointer"
		"	| %3	temporary copy of VBR"

		"	.chip 68060"
		"	movec	%%vbr,%1	| get vbr"
		"	movew	%%sr,%-		| save IPL"
		"	movel	%1@(11*4),%-	| save old trap vector (Line F)"
		"	orw	#0x700,%%sr	| disable ints"
		"	movel	#1f,%1@(11*4)	| set L1 as new vector"
		"	movel	%%sp,%2		| save stack pointer"
		"	moveql	%4,%0		| value with exception (030)"
		"	movel	%1,%3		| we move the vbr to itself"
		"	nop			| clear instruction pipeline"
		"	move16	%3@+,%3@+	| the 030 test instruction"
		"	nop			| clear instruction pipeline"
		"	moveql	%5,%0		| value with exception (040)"
		"	nop			| clear instruction pipeline"
		"	plpar	%1@		| the 040 test instruction"
		"	nop			| clear instruction pipeline"
		"	moveql	%6,%0		| value if we come here"
		"1:	movel	%2,%%sp		| restore stack pointer"
		"	movel	%+,%1@(11*4)	| restore trap vector"
		"	movew	%+,%%sr		| restore IPL"
		"	.chip 68k"
	: "=d" (rv), "=a" (temp1), "=r" (temp2), "=a" (temp3)
	: "i" (CPU_68030), "i" (CPU_68040), "i" (CPU_68060));
}

