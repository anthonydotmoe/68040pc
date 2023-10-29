`timescale 1ms/1us

module decoder_tb();

reg [1:0]	A;
reg [1:0]	SIZ;

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
	.RAS0(RAS0)
);

initial begin
	$dumpfile("decoder_tb.vcd");
	$dumpvars(0, decoder_tb);
end

initial begin


	#500;

	// Byte transfers
	SIZ	<= 2'b01;
	A	<= 2'b00;

	#500;

	$display("--------------------------------------------------------------------");
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);

	#500;

	SIZ	<= 2'b01;
	A	<= 2'b01;

	#500
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;

	SIZ	<= 2'b01;
	A	<= 2'b10;

	#500;
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;

	SIZ	<= 2'b01;
	A	<= 2'b11;

	#500;
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;
	// Word transfers
	SIZ	<= 2'b10;
	A	<= 2'b00;

	#500;
	$display("--------------------------------------------------------------------");
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;

	SIZ	<= 2'b10;
	A	<= 2'b10;

	#500;
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;
	// Long Word transfer
	SIZ	<= 2'b00;
	A	<= 2'b00;

	#500;
	$display("--------------------------------------------------------------------");
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	#500;
	// Line transfer
	SIZ	<= 2'b11;
	A	<= 2'b00;

	#500;
	$display("--------------------------------------------------------------------");
	$display("| SIZ: %b | A: %b | D31-D24: %b | D23-D16: %b | D15-D8: %b | D7-D0: %b |", SIZ, A, CAS3, CAS2, CAS1, CAS0);
	$display("--------------------------------------------------------------------");
	#500;
	// End
	$finish;
end

endmodule
