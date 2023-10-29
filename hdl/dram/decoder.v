// -----------------------------------------------------------------------------
//
// Decoder module
//
// -----------------------------------------------------------------------------

module decoder(
	// input nRESET,

	input [1:0] A,
	input SIZ1, SIZ0,
	output CAS3, CAS2, CAS1, CAS0,
	output RAS3, RAS2, RAS1, RAS0

	// output dramsel
);

// Internal signals
wire banksel;
reg [1:0] sras;

// Breaking this out makes RAS logic easier
assign RAS3 = (  sras[1] &  sras[0] );
assign RAS2 = (  sras[1] & ~sras[0] );
assign RAS1 = ( ~sras[1] &  sras[0] );
assign RAS0 = ( ~sras[1] & ~sras[0] );

// dramsel is high when address bus = 0x0000_0000 to 0x1FFF_FFFF (bits 31-29
// are 0)
// assign dramsel = ( ~A[31] & ~A[30] & ~A[29] );

// Bits A[3:0] are the data bounds for a "line". Pick a bit higher than A3 to
// use for the bank select
//assign banksel = A[6];
assign banksel = 1'b0;

// Define PAL equations from M68040UM
assign CAS3 = ((~A[0] & ~A[1]) |                 | (SIZ1 & SIZ0) | (~SIZ1 & ~SIZ0));
assign CAS2 = (( A[0] & ~A[1]) | ( ~A[1] & SIZ1) | (SIZ1 & SIZ0) | (~SIZ1 & ~SIZ0));
assign CAS1 = ((~A[0] &  A[1]) |                 | (SIZ1 & SIZ0) | (~SIZ1 & ~SIZ0));
assign CAS0 = (( A[0] &  A[1]) | (  A[1] & SIZ1) | (SIZ1 & SIZ0) | (~SIZ1 & ~SIZ0));

// RAS logic
always @(*) begin
	if (banksel == 0) begin
		if ( CAS0 || CAS1 ) sras <= 2'b00;	// RAS0
		else                sras <= 2'b10;	// RAS2
	end else begin
		if ( CAS0 || CAS1 ) sras <= 2'b01;	// RAS1
		else                sras <= 2'b11;	// RAS3
	end
end

endmodule
