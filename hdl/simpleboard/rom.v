module rom(
	input clk,
	input rst,

	input access_stb,
	input access_ack,
	input [21:0] access_addr,
	output [31:0] access_odata,

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
wire [31:0] flash_data;
wire flash_ack, flash_stall;
wire flash_reset = ~rst;
reg [21:0] flash_addr; // 24 bits minus two for long word reads
reg [3:0] flash_sel;
wire [31:0] flash_idata;
assign flash_idata = 32'b0;

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
	.i_wb_addr(flash_addr),
	.i_wb_data(flash_idata),
	.i_wb_sel(flash_sel),
	.o_wb_stall(flash_stall),
	.o_wb_ack(flash_ack),
	.o_wb_data(flash_data),

	.o_spi_cs_n(spi_ss),
	.o_spi_sck(spi_sck_en),
	.o_spi_mosi(spi_mosi),
	.i_spi_miso(spi_miso)
);

always @(posedge clk) begin
	if(rst) begin
		access_ack <= 0;
		flash_stb <= 0;
		flash_cyc <= 0;
		flash_sel <= 0;
	end else if( access_req == 1'b1 ) begin
