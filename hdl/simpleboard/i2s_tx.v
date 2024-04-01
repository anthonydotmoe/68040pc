module i2s_tx(
	input	clk,
	output	sck,
	output	lrclk,
	output	dat
);

parameter BITS_PER_CHANNEL = 32;
parameter PERIOD = 6;

reg [$clog2(BITS_PER_CHANNEL):0] counter = 0;
reg channel = 0;
reg [PERIOD:0] period = 0;

reg sck;
reg lrclk;
reg dat;

reg [2:0] clk_dff;

// SCK generation
always @(posedge clk) begin
	clk_dff <= clk_dff + 1;
	if(clk_dff == 0) begin
		sck <= ~sck;
	end
end

// LRCLK and DAT generation
always @(negedge sck) begin
	if (counter == (BITS_PER_CHANNEL-1)) begin
		lrclk <= ~lrclk;
		counter <= 0;
		channel <= ~channel;
		if (channel == 0) begin
			period <= period + 1;
		end
	end else begin
		counter <= counter + 1;
	end
	dat <= period[PERIOD];
end

endmodule
