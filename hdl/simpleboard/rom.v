module rom(
	input clk,
	input rst,

	input rom_stb,
	output rom_ack,
	input [3:0] rom_sel,
	input [21:0] rom_addr,
	output [31:0] rom_odata,

	// SPI lines
	output	spi_ss,
	output	spi_sck,
	output	spi_mosi,
	input	spi_miso,
	output	spi_io2,
	output	spi_io3
	
);

// Assign QSPI lines high for now
assign spi_io2 = 1'b1;
assign spi_io3 = 1'b1;

// Set up SCK generator
wire spi_sck_en;
oclkddr spi_ddr_sck(clk, {!spi_sck_en, 1'b1}, spi_sck);

// Setup SPI reader lines
reg flash_stb, flash_cyc;
wire flash_stall, flash_reset;
assign flash_reset = ~rst;

// Instantiate SPI reader
spixpress #(
	.OPT_CFG(1'b0),
	.OPT_PIPE(1'b0)
) reader(
	.i_clk(clk),
	.i_reset(flash_reset),

	.i_wb_cyc(flash_cyc),
	.i_wb_stb(flash_stb),
	.i_wb_we(1'b0),
	.i_wb_addr(rom_addr),
	.i_wb_data(32'b0),
	.i_wb_sel(rom_sel),
	.o_wb_stall(flash_stall),
	.o_wb_ack(rom_ack),
	.o_wb_data(rom_odata),

	.o_spi_cs_n(spi_ss),
	.o_spi_sck(spi_sck_en),
	.o_spi_mosi(spi_mosi),
	.i_spi_miso(spi_miso)
);

reg waitstate;

always @(posedge clk) begin
	if(~rst) begin
		flash_stb <= 0;
		flash_cyc <= 0;
		waitstate <= 0;
	end else begin
		if (waitstate == 0) begin
			flash_stb <= 0;
			flash_cyc <= 0;

			if( rom_stb == 1'b1 ) begin
				flash_stb <= 1;
				flash_cyc <= 1;
				waitstate <= 1;
			end
		end else begin
			flash_stb <= 0;
				
			if( rom_ack == 1 ) begin
				flash_cyc <= 0;
				waitstate <= 0;
			end
		end
	end
end
endmodule
