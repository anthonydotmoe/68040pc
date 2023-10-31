/*
`timescale 1ms/1us

module decoder_tester();

reg [31:0]	A;
reg [1:0]	SIZ;

wire [1:0]	modsel;
wire [11:0]	row_addr;
wire [11:0]	col_addr;

wire		dramsel;

wire CAS3, CAS2, CAS1, CAS0;
wire RAS3, RAS2, RAS1, RAS0;

decoder decoder_inst(
	.A(A),
	.SIZ1(SIZ[1]),
	.SIZ0(SIZ[0]),

	.CAS3(CAS3),
	.CAS2(CAS2),
	.CAS1(CAS1),
	.CAS0(CAS0),
	.RAS3(RAS3),
	.RAS2(RAS2),
	.RAS1(RAS1),
	.RAS0(RAS0),

	.modsel(modsel),
	.row_addr(row_addr),
	.col_addr(col_addr),

	.dramsel(dramsel)
);

initial begin
	$dumpfile("decoder_tb.vcd");
	$dumpvars(0, decoder_tb);
end

initial begin


	#500;

	// Byte transfers
	SIZ	<= 2'b01;
	A	<= 32'h2000_0000;

	#500;

	$display("--------------------------------------------------------------------");
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);

	#500;

	SIZ	<= 2'b01;
	A	<= 32'h2000_0001;

	#500
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;

	SIZ	<= 2'b01;
	A	<= 32'h2000_0002;

	#500;
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;

	SIZ	<= 2'b01;
	A	<= 32'h2000_0003;

	#500;
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;
	// Word transfers
	SIZ	<= 2'b10;
	A	<= 32'h2000_0000;

	#500;
	$display("--------------------------------------------------------------------");
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;

	SIZ	<= 2'b10;
	A	<= 31'h2000_0002;

	#500;
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;
	// Long Word transfer
	SIZ	<= 2'b00;
	A	<= 32'h2000_0000;

	#500;
	$display("--------------------------------------------------------------------");
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;
	// Line transfer
	SIZ	<= 2'b11;
	A	<= 32'h2000_0000;

	#500;
	$display("--------------------------------------------------------------------");
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	$display("--------------------------------------------------------------------");
	#500;







	// Now we test DRAM selection
	
	SIZ	<= 2'b01;
	A	<= 32'h1fff_ffff;

	#1000;
	A	<= 32'h4000_0000;
	#1000;

	// Test module, row, column, bank selection
	
	// (DRAM)_(Row 0xAAA)_(Bank 0)_(Module 0)_(Col 0x555)_(Byte 0)
	A	<= 32'b001_101010101010_0_00_010101010101_00;
	#1000;
	
	// (DRAM)_(Row 0xAAA)_(Bank 0)_(Module 1)_(Col 0x555)_(Byte 0)
	A	<= 32'b001_101010101010_0_01_010101010101_00;
	#1000;
	
	// (DRAM)_(Row 0xAAA)_(Bank 0)_(Module 2)_(Col 0x555)_(Byte 0)
	A	<= 32'b001_101010101010_0_10_010101010101_00;
	#1000;
	
	// (DRAM)_(Row 0xAAA)_(Bank 0)_(Module 3)_(Col 0x555)_(Byte 0)
	A	<= 32'b001_101010101010_0_11_010101010101_00;
	#1000;
	
	// (DRAM)_(Row 0xAAA)_(Bank 1)_(Module 0)_(Col 0x555)_(Byte 0)
	A	<= 32'b001_101010101010_1_00_010101010101_00;
	#1000;
	
	// (DRAM)_(Row 0xAAA)_(Bank 1)_(Module 1)_(Col 0x555)_(Byte 0)
	A	<= 32'b001_101010101010_1_01_010101010101_00;
	#1000;
	
	// (DRAM)_(Row 0xAAA)_(Bank 1)_(Module 2)_(Col 0x555)_(Byte 0)
	A	<= 32'b001_101010101010_1_10_010101010101_00;
	#1000;
	
	// (DRAM)_(Row 0xAAA)_(Bank 1)_(Module 3)_(Col 0x555)_(Byte 0)
	A	<= 32'b001_101010101010_1_11_010101010101_00;
	#1000;




	
	// End
	$finish;
end

endmodule
*/
