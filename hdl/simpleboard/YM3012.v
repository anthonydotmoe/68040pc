/*---------------------------------------------------------------------------------------
	Imported from http://www.geocities.jp/team_zero_three/YM2151/

	[YM3012]

		Implements a YM3012 --> uPD6376 data format converter.

	2011/7/22 Ki
---------------------------------------------------------------------------------------*/

module YM3012(
	i_CLOCK,
	i_nICL,
	i_SD,
	i_SAM1,
	i_SAM2,
	o_Data,
	o_LRCK
);

	input			i_CLOCK;
	input			i_nICL;
	input			i_SD;
	input			i_SAM1;
	input			i_SAM2;

	output			o_Data;
	output			o_LRCK;

	reg		[12:0]	r_SR;		// input shift register 
	reg		[15:0]	r_D1;		// output data register
	reg		[15:0]	r_D2;		// output data register
	reg				r_PrevSAM1;
	reg				r_PrevSAM2;
	reg				r_NegEdgeSAM1;
	reg				r_NegEdgeSAM2;
	reg				r_LRCK;

	wire			w_NegEdgeSAM1	= r_PrevSAM1 & ~i_SAM1;
	wire			w_NegEdgeSAM2	= r_PrevSAM2 & ~i_SAM2;

	always @(posedge i_CLOCK or negedge i_nICL) begin
		if (~i_nICL) begin
			r_SR		<= 13'h0;
			r_PrevSAM1	<= 0;
			r_PrevSAM2	<= 0;
			r_NegEdgeSAM1 <= 0;
			r_NegEdgeSAM2 <= 0;
		end
		else begin
			r_PrevSAM1 <= i_SAM1;
			r_PrevSAM2 <= i_SAM2;

			r_NegEdgeSAM1 <= w_NegEdgeSAM1;
			r_NegEdgeSAM2 <= w_NegEdgeSAM2;

			if (~(w_NegEdgeSAM1 | w_NegEdgeSAM2))	r_SR <= { i_SD, r_SR[12:1] };
		end
	end

	always @(negedge i_CLOCK or negedge i_nICL) begin
		if (~i_nICL) begin
			r_D1		<= 0;
			r_D2		<= 0;
			r_LRCK		<= 1;
		end
		else begin
			if (r_NegEdgeSAM1) begin
				r_LRCK <= 1;
				case (r_SR[12:10])
					// 10'h3ff = +511, 10'h200 = +-0, 10'h1ff = -1, 10'h000=-512 
					3'h0:	r_D1 <= { {8{~r_SR[9]}}, r_SR[8:1] };		// "not allowed" 
					3'h1:	r_D1 <= { {7{~r_SR[9]}}, r_SR[8:0] };
					3'h2:	r_D1 <= { {6{~r_SR[9]}}, r_SR[8:0], 1'b0 };
					3'h3:	r_D1 <= { {5{~r_SR[9]}}, r_SR[8:0], 2'b00 };
					3'h4:	r_D1 <= { {4{~r_SR[9]}}, r_SR[8:0], 3'b000 };
					3'h5:	r_D1 <= { {3{~r_SR[9]}}, r_SR[8:0], 4'b0000 };
					3'h6:	r_D1 <= { {2{~r_SR[9]}}, r_SR[8:0], 5'b00000 };
					3'h7:	r_D1 <= { ~r_SR[9], r_SR[8:0], 6'b000000 };
				endcase
			end
			else begin
				if (r_LRCK)	r_D1 <= { r_D1[14:0], 1'b0 };
			end

			if (r_NegEdgeSAM2) begin
				r_LRCK <= 0;
				case (r_SR[12:10])
					3'h0:	r_D2 <= { {8{~r_SR[9]}}, r_SR[8:1] };		// "not allowed" 
					3'h1:	r_D2 <= { {7{~r_SR[9]}}, r_SR[8:0] };
					3'h2:	r_D2 <= { {6{~r_SR[9]}}, r_SR[8:0], 1'b0 };
					3'h3:	r_D2 <= { {5{~r_SR[9]}}, r_SR[8:0], 2'b00 };
					3'h4:	r_D2 <= { {4{~r_SR[9]}}, r_SR[8:0], 3'b000 };
					3'h5:	r_D2 <= { {3{~r_SR[9]}}, r_SR[8:0], 4'b0000 };
					3'h6:	r_D2 <= { {2{~r_SR[9]}}, r_SR[8:0], 5'b00000 };
					3'h7:	r_D2 <= { ~r_SR[9], r_SR[8:0], 6'b000000 };
				endcase
			end
			else begin
				if (~r_LRCK)	r_D2 <= { r_D2[14:0], 1'b0 };
			end
		end
	end

	/*-----------------------------------------------------------------------------------
		[output]
	-----------------------------------------------------------------------------------*/
	assign	o_Data = r_LRCK ? r_D1[15] : r_D2[15];
	assign	o_LRCK = r_LRCK;

endmodule
