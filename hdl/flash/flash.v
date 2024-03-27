`define DEBUG

(* top *)
module flash (
	input	clk,
	input	rst,
	input	btn,
	output	led,

	output	d_dir,
	output	d_oe,

	input	[31:0]	a,
	output	[31:0]	d,

`ifdef DEBUG
	output	dbg1,
	output	dbg2,
	output	dbg3,
`endif

	input	ts,
	output	ta,
	output	tea,
	input	tip,
	output	tci,
	output	tbi,
	input	[1:0]	tt,
	input	[2:0]	tm,
	input	[1:0]	siz,

	input	rw,

	output	[1:0]	DSACK,
	input		RESIZ_DS,
	output		RESIZ_CS,

	output		COM_CS,
	input		COM_IRQ,
	output		COM_IACK,

	output		RAM_CS,

	output	[2:0]	IPL,
	output		AVEC,

	output	spi_ss,
	output	spi_sck,
	output	spi_mosi,
	input	spi_miso,
	output	spi_io2,
	output	spi_io3
);

// Assign default states
assign d_dir = 1;
assign tci = 1;
assign tbi = 0;
assign tea = 1;
assign spi_io2 = 1;
assign spi_io3 = 1;

assign IPL = 3'b111;
assign AVEC = 1'b1;

assign RAM_CS = 0;
assign COM_CS = 0;
assign RESIZ_CS = 0;
assign COM_IACK = 0;

assign DSACK = 2'b11;

// End assign

// A/D Buffer
reg [31:0] addr;
reg [31:0] d;

reg i_ta;

assign ta = ~i_ta;

`ifdef DEBUG
// Yellow
assign dbg1 = ts;
// Blue
assign dbg2 = ram_access;
// Dark
assign dbg3 = spi_mosi;
`endif



reg d_oe;
reg flash_stb, flash_cyc;
wire [31:0] flash_data;
wire flash_ack, flash_stall;
wire flash_reset = ~rst;

wire spi_sck_en;
reg [21:0] flash_addr; // 24 bits minus two for long word reads
oclkddr spi_ddr_sck(clk, {!spi_sck_en, 1'b1}, spi_sck);

reg [3:0] flash_sel;

wire [31:0] flash_idata;

assign flash_idata = 32'b0;

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

reg [2:0] state;

//reg [3:0] count;

localparam	START = 0,
		GET_DATA = 1,
		WAIT_DATA = 2,
		START_TA = 3,
		FINISH_TA = 4;

localparam FLASH_PAGE = 8'h04;

wire rom_sel;
assign rom_sel = (addr[31:28] == 4'h0);

wire duart_sel;
assign duart_sel = (addr[31:28] == 4'h2);

wire ram_sel;
assign ram_sel = (addr[31:28] == 4'h3);

wire fpga_sel;
assign fpga_sel = (addr[31:28] == 4'h8);

wire rom_access = ( (tip == 0) && (rom_sel == 1) );
wire ram_access = ( (tip == 0) && (ram_sel == 1) );	// 55nS
wire uart_access = ( (tip == 0) && (ram_sel == 1) );

always @(posedge clk or negedge rst) begin
	if (~rst) begin
		state <= START;
		i_ta <= 1'b0;
		d_oe <= 1;
		flash_stb <= 0;
		flash_cyc <= 0;
		flash_sel <= 0;
	end else begin
		case (state)
			START: begin
				i_ta <= 0;
				d_oe <= 1;
				flash_stb <= 0;
				flash_cyc <= 0;
				flash_sel <= 0;

				if( rom_access == 1'b1 && ts == 1 ) begin
					flash_addr <= { (addr[23:16] + FLASH_PAGE ), addr[15:2] };
					state <= GET_DATA;
				end else begin
					state <= START;
				end
			end
			GET_DATA: begin
				i_ta <= 0;
				d_oe <= 1;

				flash_sel <= 4'b1111;
				flash_stb <= 1;
				flash_cyc <= 1;
				state <= WAIT_DATA;
			end
			WAIT_DATA: begin
				i_ta <= 0;
				d_oe <= 1;
				flash_stb <= 0;

				if( flash_ack == 1 ) begin
					flash_cyc <= 0;
					flash_sel <= 0;
					d <= flash_data;
					state <= START_TA;
				end
			end
			START_TA: begin
				i_ta <= 1;
				d_oe <= 0;
				state <= FINISH_TA;
			end
			FINISH_TA: begin
				i_ta <= 0;
				d_oe <= 1;

				state <= START;
			end
		endcase
	end
end

// Latch address when TS is asserted
always @(posedge clk) begin
	if (ts == 1'b0)
		addr <= a;
end

wire blink_en;
assign blink_en = (state == START);
reg [22:0] blink_count;
always @(posedge clk) begin
	blink_count <= blink_count + 1;
end

//assign led = (blink_en == 1'b1) ? blink_count[22] : 1'b1;
assign led = (blink_en == 1'b1) ? 1'b0 : 1'b1;

endmodule
