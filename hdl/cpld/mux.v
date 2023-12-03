module mux (
	input	[31:0]	A,
	input	[3:0]	ras,
	output	[11:0]	m_addr
);

(* keep *)
wire ras_asserted;

(* keep *)
wire delayed_ras_asserted;

assign ras_asserted = ~(ras == 4'b1111);
assign delayed_ras_asserted = ras_asserted;

assign m_addr = (delayed_ras_asserted == 1'b1) ? A[13:2] : A[28:17];

endmodule
