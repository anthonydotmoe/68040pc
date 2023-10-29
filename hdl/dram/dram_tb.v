`timescale 1ns/1ps

module dram_tb();

// 33MHz BCLK
localparam HALF_PERIOD = 15.15;

reg	[7:0]	bus_cycle;

// System Signals
reg		nRESET;	// System Reset
wire	[31:0]	D;	// Data Bus

// 68040 Signals
reg		BCLK;	// Bus Clock
reg	[31:0]	A;	// (O) Address Bus
reg	[31:0]	DU;	// Internal data bus
reg		D_EN;	// Data bus output buffer enable
reg	[1:0]	SIZ;	// (O) Transfer Size
reg	[1:0]	TT;	// (O) Transfer Type
reg	[2:0]	TM;	// (O) Transfer Modifiers
reg		RW;	// (O) Read/nWrite
reg		TS;	// (O) Transfer Start
reg		TIP;	// (O) Transfer in progress
reg		TA;	// (I) Transfer Acknowledge
reg		TBI;	// (I) Transfer Burst Inhibit
cpu_databus m68040db (
	.clk(BCLK),
	.en(D_EN),
	.data_in(DU),
	.data_bus(D)
);

// -----------------------------------------------------------------------------

// Test Burst read from DRAM
initial begin
	// Clock pin starts high
	
	// 68040 initial state
	nRESET	= 1'b0;
	DU	= 32'b0;
	D_EN	= 1'b0;
	SIZ	= 2'b0;
	TT	= 2'b0;
	TM	= 3'b0;
	RW	= 1'b1;
	TS	= 1'b1;
	TIP	= 1'b1;

	// DRAM Controller initial state (will be removed when actual dram
	// controller is added
	TA	= 1'b1;

	bus_cycle = "I";

	// De-assert reset after one clock
	#(2*HALF_PERIOD);
	nRESET	= 1'b1;

	bus_cycle = "1";

	// Sync 68040 with falling edge
	#(HALF_PERIOD);

	// (C1)
	// Start of transfer, assert lines
	A	= 32'h0000_0000;
	SIZ	= 2'b11;	// Line Transfer
	TT	= 2'b00;	// Normal Access
	TM	= 3'b110;	// Supervisor Code Access
	RW	= 1'b1;		// Read
	TS	= 1'b0;		// Assert Transfer Start for one clock
	TIP	= 1'b0;		// Transfer in progress

	// (C2)
	#(HALF_PERIOD);
	bus_cycle = "2";
	#(HALF_PERIOD);
	TS	= 1'b1;		// De-assert Transfer Start

	// While TA is unasserted, insert wait state
	// (CW)
	while(TA == 1'b1) begin
		#(HALF_PERIOD);
		bus_cycle = "W";
		#(HALF_PERIOD);
	end

	//TODO: C3-C5
	// (C3)
	#(HALF_PERIOD);
	bus_cycle = "3";
	#(HALF_PERIOD);
	
	// (C4)
	#(HALF_PERIOD);
	bus_cycle = "4";
	#(HALF_PERIOD);
	
	// (C5)
	#(HALF_PERIOD);
	bus_cycle = "5";
	#(HALF_PERIOD);
	
	// After (C5)
	#(2*HALF_PERIOD);
	TIP	= 1'b1;		// De-assert transfer in progress

	// Notify and end simulation
	$display("Finished!");
	$finish;
end

// Clock generator
initial begin
	BCLK = 1'b1;
	forever #(HALF_PERIOD) BCLK = ~BCLK;
end


initial begin
	// Create simulation output file 
	$dumpfile("dram_tb.vcd");
	$dumpvars(0, dram_tb);
end

// Timeout
initial begin
	#(1000*HALF_PERIOD);

	$display("Timeout!");
	$finish;
end

endmodule

module cpu_databus(
	input wire clk,
	input wire en,
	input wire [31:0] data_in,
	inout wire [31:0] data_bus
);

reg [31:0] internal_data;

always @(posedge clk) begin
	if (en)
		internal_data <= data_in;
	else
		internal_data <= 32'bz;
end

assign data_bus = en ? internal_data : 32'bz;

endmodule
