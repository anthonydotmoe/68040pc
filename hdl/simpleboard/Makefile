TOP		:= top
BUILD	:= output
PCF		:= pins.pcf

RTL	:= \
	rtl/top.v \
	rtl/oclkddr.v \
	rtl/spixpress.v \
	rtl/wbarbiter.v \
	rtl/debounce.v \
	rtl/rom.v \
	rtl/fpga_int.v \

JSON		:= $(BUILD)/hardware.json
ASC			:= $(BUILD)/hardware.asc
BIN			:= $(BUILD)/hardware.bin
PNR_RPT		:= $(BUILD)/hardware.pnr.json
TIME_RPT	:= $(BUILD)/hardware.time.txt

DEVICE	:= --hx8k
PACKAGE	:= --package tq144:4k
FREQ	:= 33

.PHONY: all build upload lint synth pnr pack time test test-debounce clean

all: build

$(BUILD):
	mkdir -p $(BUILD)

build: $(BIN)

$(JSON): $(RTL) | $(BUILD)
	yosys -q -p "synth_ice40 -top $(TOP) -json $(JSON)" $(RTL)

$(ASC): $(JSON) $(PCF)
	nextpnr-ice40 \
		$(DEVICE) $(PACKAGE) \
		--json $(JSON) \
		--asc $(ASC) \
		--pcf $(PCF) \
		--freq $(FREQ) \
		--report $(PNR_RPT)

$(BIN): $(ASC)
	icepack -s $(ASC) $(BIN)

upload: $(BIN)
	iceprog $(BIN)

time: $(ASC)
	icetime -d hx8k -mtr $(TIME_RPT) $(ASC)
	cat $(TIME_RPT)

lint:
	verilator --lint-only -Wall $(RTL)

test: test-debounce

test-debounce: $(BUILD)/debounce_tb
	vvp $(BUILD)/debounce_tb

$(BUILD)/debounce_tb: rtl/debounce.v tb/debounce_tb.v | $(BUILD)
	iverilog -g2012 -Wall -o $@ tb/debounce_tb.v rtl/debounce.v

clean:
	rm -rf $(BUILD)
