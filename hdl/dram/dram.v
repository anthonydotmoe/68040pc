// -----------------------------------------------------------------------------
//
// Top-level module for DRAM controller
//
// -----------------------------------------------------------------------------
(* top *)
module dram(


// 68040 signals

	// Timing
	input 	clk,		// Input clock
	input 	nRESET,		// Reset

	// A/D Bus
	input 	[31:0] A,	// Address Bus

	// Transfer Attributes
	input 	[1:0] TT,	// Transfer Type
//	input 	[2:0] TM,	// Transfer Modifier
	input 	[1:0] SIZ,	// Transfer Size
	input 	nWR,		// Read/nWrite

	// Transfer Control
	input 	nTS,		// Transfer Start
	output	nTA,		// Transfer Acknowledge
//	output	nTBI,		// Transfer Burst Inhibit

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
	output	[3:0]	nCASD	// Column Address Strobe (Module D)

	// Module Detection
	// TODO: Implement detection

//	input	[3:0]	PDA,	// Presence Detect (Module A)
//	input	[3:0]	PDB,	// Presence Detect (Module B)
//	input	[3:0]	PDC,	// Presence Detect (Module C)
//	input	[3:0]	PDD,	// Presence Detect (Module D)
);

// Internal signals
wire dramsel;
wire banksel;

// Signals to connect the modules together
wire		dec_dramsel;
wire	[3:0]	dec_cas;
wire	[3:0]	dec_ras;
wire	[1:0]	dec_modsel;
wire	[11:0]	row_addr;
wire	[11:0]	col_addr;

// ----------------
// -- Addressing --
// ----------------

// Enable DRAM controller when Address bus = 0x2000_0000 to 0x3FFF_FFFF
assign dramsel = (dec_dramsel & nMI );

decoder decoder_inst(
	.A(A),
	.SIZ1(SIZ[1]),
	.SIZ0(SIZ[0]),

	.CAS3(dec_cas[3]),
	.CAS2(dec_cas[2]),
	.CAS1(dec_cas[1]),
	.CAS0(dec_cas[0]),
	.RAS3(dec_ras[3]),
	.RAS2(dec_ras[2]),
	.RAS1(dec_ras[1]),
	.RAS0(dec_ras[0]),

	.modsel(dec_modsel),
	.row_addr(row_addr),
	.col_addr(col_addr),
	.dramsel(dec_dramsel)
);

mux mux_inst(
	.A(A),
	.ras(nRAS),
	.m_addr(DRAMA)
);

sm sm_inst(
	.clk(clk),
	.nRESET(nRESET),

	.dramsel(dramsel),

	.row_addr(row_addr),
	.col_addr(col_addr),
	.dec_ras(dec_ras),
	.dec_cas(dec_cas),
	.modsel(dec_modsel),

//	.m_addr(DRAMA),
	.ras(nRAS),
	.casa(nCASA),
	.casb(nCASB),
	.casc(nCASC),
	.casd(nCASD),

	.nTS(nTS),
	.nTA(nTA),
	.nWR(nWR)
);

endmodule
