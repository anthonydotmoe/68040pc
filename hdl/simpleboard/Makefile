build:
	yosys -p "synth_ice40 -json output/hardware.json" -q top.v oclkddr.v spixpress.v wbarbiter.v debounce.v #i2s_tx.v
	nextpnr-ice40 --hx8k --package tq144:4k --json output/hardware.json --asc output/hardware.asc --pcf pins.pcf -q
	icepack -s output/hardware.asc output/hardware.bin

upload:
	iceprog output/hardware.bin

rom:
	iceprog -o 256k ../../firmware/rom.bin
