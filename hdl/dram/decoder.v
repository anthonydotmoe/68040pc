// -----------------------------------------------------------------------------
//
// Decoder module
//
// -----------------------------------------------------------------------------

module decoder(
	input nRESET;

	input A31, A30, A29, A0;
	input nTS;

	output dramsel;
	);

// -----------------
// 
// Address Decoding
//
// -----------------

// dramsel is high when address bus = 0x0000_0000 to 0x1FFF_FFFF (bits 31-29
// are 0)
assign dramsel = ( !A31 & !A30 & !A29 );

