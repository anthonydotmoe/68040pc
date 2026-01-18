const unsigned int TEST_PATTERN = 0x55555555;

unsigned int get_memsize(volatile unsigned int *base) {

	unsigned int offset = 0;
	unsigned int readval = 0;
	unsigned int testpattern = TEST_PATTERN;

	for(int i = 1; i < 29; i++) {
		readval = 0;
		offset |= (1 << i);
		offset &= 0xFFFFFFFC;

		for(int j = 0; j < 2; j++) {
			testpattern = j ? testpattern : ~testpattern;
			*(base + offset) = testpattern;
			readval = *(base + offset);

			if(readval != testpattern) {
				return (offset >> 1);
			}
		}
	}
	return (offset >> 1);
}
