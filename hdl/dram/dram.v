// -----------------------------------------------------------------------------
//
// Top-level module for DRAM controller
//
// -----------------------------------------------------------------------------

module dram(


// 68040 signals

	// Timing
	input 	clk,		// Input clock
	input 	nRESET,		// Reset

	// A/D Bus
	input 	[31:0] A,	// Address Bus

	// Transfer Attributes
	input 	[1:0] TT,	// Transfer Type
	input 	[2:0] TM,	// Transfer Modifier
	input 	[1:0] SIZ,	// Transfer Size
	input 	RW,		// Read/nWrite

	// Transfer Control
	input 	nTS,		// Transfer Start
	output	nTA,		// Transfer Acknowledge
	output	nTBI,		// Transfer Burst Inhibit

	// Snoop Control Signals
	input	nMI,		// Memory Inhibit

// DRAM signals
	
	// Addressing
	output	[11:0] DRAMA,	// DRAM Multiplexed Address Bus

	// RAS and CAS lines are arrays to make things easier
	output	[3:0]	nRAS,	// Row Address Strobe
	output	[3:0]	nCASA,	// Column Address Strobe (Module A)
	output	[3:0]	nCASB,	// Column Address Strobe (Module B)
	output	[3:0]	nCASC,	// Column Address Strobe (Module C)
	output	[3:0]	nCASD,	// Column Address Strobe (Module D)

	// Module Detection
	/* TODO: Implement detection

	input	[3:0]	PDA,	// Presence Detect (Module A)
	input	[3:0]	PDB,	// Presence Detect (Module B)
	input	[3:0]	PDC,	// Presence Detect (Module C)
	input	[3:0]	PDD,	// Presence Detect (Module D)
	*/
);

// Internal signals
wire dramsel;
wire banksel;

// ----------------
// -- Addressing --
// ----------------

// Enable DRAM controller when Address bus = 0x0000_0000 to 0x1FFF_FFFF
assign dramsel = (( ~A[31] & ~A[30] & ~A[29] ) & ~nMI );
assign banksel = A[16];



sm sm_inst(
	.clk(clk),
	.nRESET(nRESET)
);

endmodule
