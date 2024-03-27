build:
	yosys -p "synth_ice40 -json hardware.json" -q flash.v oclkddr.v spixpress.v wbarbiter.v
	nextpnr-ice40 --hx8k --package tq144:4k --json hardware.json --asc hardware.asc --pcf pins.pcf -q
	icepack -s hardware.asc hardware.bin

apiobuild:
	apio build --fpga iCE40-HX4K-TQ144

upload:
	iceprog hardware.bin

rom:
	iceprog -o 256k ../../firmware/rom.bin

test:
	iceprog -o 256k test.bin
