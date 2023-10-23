// -----------------------------------------------------------------------------
//
// Top-level module for DRAM controller
//
// -----------------------------------------------------------------------------

module dram(


// 68040 signals

	// Timing
	input 	CLK;		// Input clock
	input 	nRESET;		// Reset

	// A/D Bus
	input 	[23:0] A;	// Address Bus
	inout 	[32:0] D;	// Data Bus

	// Transfer Attributes
	input 	[1:0] TT;	// Transfer Type
	input 	[2:0] TM;	// Transfer Modifier
	input 	[1:0] SIZ;	// Transfer Size
	input 	RW;		// Read/nWrite

	// Transfer Control
	input 	nTS;		// Transfer Start
	output	nTA;		// Transfer Acknowledge
	output	nTBI;		// Transfer Burst Inhibit

	// Snoop Control Signals
	input	nMI;		// Memory Inhibit

// DRAM signals
	
	// Addressing
	output	[11:0] DRAMA;	// DRAM Multiplexed Address Bus

	output	nRAS0;		// Row Address Select
	output	nRAS1;
	output	nRAS2;
	output	nRAS3;

	output	nCASA0;		// Column Address Select (Module A)
	output	nCASA1;
	output	nCASA2;
	output	nCASA3;

	output	nCASB0;		// Column Address Select (Module B)
	output	nCASB1;
	output	nCASB2;
	output	nCASB3;

	output	nCASC0;		// Column Address Select (Module C)
	output	nCASC1;
	output	nCASC2;
	output	nCASC3;

	output	nCASD0;		// Column Address Select (Module D)
	output	nCASD1;
	output	nCASD2;
	output	nCASD3;

	output	DRAMRW;		// DRAM Read/nWrite

	// Module Detection
	/* TODO: Implement detection
	
	input	PDA1;		// Presence Detect (Module A)
	input	PDA2;
	input	PDA3;
	input	PDA4;
	
	input	PDB1;		// Presence Detect (Module B)
	input	PDB2;
	input	PDB3;
	input	PDB4;
	
	input	PDC1;		// Presence Detect (Module C)
	input	PDC2;
	input	PDC3;
	input	PDC4;
	
	input	PDD1;		// Presence Detect (Module D)
	input	PDD2;
	input	PDD3;
	input	PDD4;

	*/
	);


