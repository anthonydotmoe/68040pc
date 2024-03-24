build:
	apio build --fpga iCE40-HX4K-TQ144

upload:
	apio raw "iceprog hardware.bin"

rom:
	apio raw "iceprog -o 256k ../../firmware/rom.bin"

test:
	apio raw "iceprog -o 256k test.bin"
