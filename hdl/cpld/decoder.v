// -----------------------------------------------------------------------------
//
// Decoder module
//
// -----------------------------------------------------------------------------

module decoder(
	// input nRESET,

	input [31:0]	A,
	input 		SIZ1, SIZ0,

	output		CAS3, CAS2, CAS1, CAS0,
	output		RAS3, RAS2, RAS1, RAS0,
	output [1:0]	modsel,
	output [11:0]	row_addr,
	output [11:0]	col_addr,

	output		dramsel
);

// Internal signals
wire banksel;
reg [1:0] sras;

// Breaking this out makes RAS logic easier
// assign RAS3 = (  sras[1] &  sras[0] );
// assign RAS2 = (  sras[1] & ~sras[0] );
// assign RAS1 = ( ~sras[1] &  sras[0] );
// assign RAS0 = ( ~sras[1] & ~sras[0] );


// ----------------------------------
// -- Address bus to DRAM decoding --
// ----------------------------------

// dramsel is high when address bus = 0x2000_0000 to 0x3FFF_FFFF (bits 31-29
// are 3'b001)
assign dramsel = ( ~A[31] & ~A[30] & A[29] );

// pick the bank with A16
assign banksel = A[16];

// row and column address
assign row_addr = A[28:17];
assign col_addr = A[13:2];

// pick the module with A[15:14]
assign modsel = A[15:14];

// Define PAL equations from M68040UM
assign CAS3 = ((~A[0] & ~A[1]) |                 | (SIZ1 & SIZ0) | (~SIZ1 & ~SIZ0));
assign CAS2 = (( A[0] & ~A[1]) | ( ~A[1] & SIZ1) | (SIZ1 & SIZ0) | (~SIZ1 & ~SIZ0));
assign CAS1 = ((~A[0] &  A[1]) |                 | (SIZ1 & SIZ0) | (~SIZ1 & ~SIZ0));
assign CAS0 = (( A[0] &  A[1]) | (  A[1] & SIZ1) | (SIZ1 & SIZ0) | (~SIZ1 & ~SIZ0));

// RAS logic

assign RAS0 = (( CAS0 || CAS1 ) & ~banksel);
assign RAS1 = (( CAS0 || CAS1 ) &  banksel);
assign RAS2 = (( CAS2 || CAS3 ) & ~banksel);
assign RAS3 = (( CAS2 || CAS3 ) &  banksel);

/*
always @(*) begin
	if (banksel == 0) begin
		RAS0 = ( CAS0 || CAS1 ) ? 1'b1 : 1'b0;
		RAS2 = ( CAS2 || CAS3 ) ? 1'b1 : 1'b0;
		RAS1 = 1'b0;
		RAS3 = 1'b0;
	end else begin
		RAS1 = ( CAS0 || CAS1 ) ? 1'b1 : 1'b0;
		RAS3 = ( CAS2 || CAS3 ) ? 1'b1 : 1'b0;
		RAS0 = 1'b0;
		RAS2 = 1'b0;
	end
end
*/

endmodule
