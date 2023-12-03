`timescale 1ns/1ps

module dram_tb();

// 33MHz BCLK
localparam HALF_PERIOD = 15.15;

reg	[7:0]	bus_cycle;

// System Signals
reg		nRESET;	// System Reset

// 68040 Signals
reg		BCLK;	// Bus Clock
reg	[31:0]	A;	// (O) Address Bus
reg	[1:0]	SIZ;	// (O) Transfer Size
reg	[1:0]	TT;	// (O) Transfer Type
reg	[2:0]	TM;	// (O) Transfer Modifiers
reg		RW;	// (O) Read/nWrite
reg		TS;	// (O) Transfer Start
reg		TIP;	// (O) Transfer in progress
wire		TA;	// (I) Transfer Acknowledge
wire		TBI;	// (I) Transfer Burst Inhibit

// DRAM signals
wire	[11:0]	DRAMA;
wire	[3:0]	RAS;
wire	[3:0]	CASA;
wire	[3:0]	CASB;
wire	[3:0]	CASC;
wire	[3:0]	CASD;


// -----------------------------------------------------------------------------

dram dram_inst(
	.clk(BCLK),
	.nRESET(nRESET),
	
	.A(A),

	.TT(TT),
	.SIZ(SIZ),
	.nWR(RW),

	.nTS(TS),
	.nTA(TA),

	.nMI(1'b1),

	.nRAS(RAS),
	.nCASA(CASA),
	.nCASB(CASB),
	.nCASC(CASC),
	.nCASD(CASD)
);

// Test Burst read from DRAM
initial begin
	// Clock pin starts high
	
	// 68040 initial state
	nRESET	= 1'b0;
	SIZ	= 2'b0;
	TT	= 2'b0;
	TM	= 3'b0;
	RW	= 1'b1;
	TS	= 1'b1;
	TIP	= 1'b1;

	bus_cycle = "I";

	// De-assert reset after one clock
	#(2*HALF_PERIOD);
	nRESET	= 1'b1;

	bus_cycle = "1";

	// Sync 68040 with falling edge
	#(HALF_PERIOD);

	// (C1)
	// Start of transfer, assert lines
	A	<= 32'b001_101010101010_0_00_010101010101_00;
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

	// (C3)
	#(HALF_PERIOD);
	bus_cycle = "3";
	#(HALF_PERIOD);
	while(TA == 1'b1) begin
		#(HALF_PERIOD);
		bus_cycle = "W";
		#(HALF_PERIOD);
	end
	
	// (C4)
	#(HALF_PERIOD);
	bus_cycle = "4";
	#(HALF_PERIOD);
	while(TA == 1'b1) begin
		#(HALF_PERIOD);
		bus_cycle = "W";
		#(HALF_PERIOD);
	end
	
	// (C5)
	#(HALF_PERIOD);
	bus_cycle = "5";
	#(HALF_PERIOD);
	while(TA == 1'b1) begin
		#(HALF_PERIOD);
		bus_cycle = "W";
		#(HALF_PERIOD);
	end
	
	// After (C5)
	#(2*HALF_PERIOD);
	TIP	= 1'b1;		// De-assert transfer in progress
	A	= 32'hD000_0000;

	#(10*HALF_PERIOD);

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
	#(1000*1000);

	$display("Timeout!");
	$finish;
end

endmodule
