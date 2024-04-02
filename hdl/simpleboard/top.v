//`define SOUND
(* top *)
module top (
	input	clk,
	input	rst,
	input	btn,
	output	led,

	output	d_dir,
	output	d_oe,

	input	[31:0]	a,
	output	[31:0]	d,

`ifdef SOUND
	output	i2s_bclk,
	output	i2s_dat,
	output	i2s_lrclk,
`endif

	output	i2s_bclk,

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
assign spi_io2 = 1;
assign spi_io3 = 1;


assign COM_IACK = 0;

reg ram_ack;
wire [1:0] DSACK;
assign DSACK[0] = 1'b1;
assign DSACK[1] = ~ram_ack;

// End assign

// A/D Buffer
reg [31:0] addr;
reg [31:0] d;

reg i_tea;
assign tea = ~i_tea;

reg i_ta;
assign ta = ~i_ta;


`ifdef SOUND
// Noisemaker
i2s_tx sound(
	.clk(clk),
	.sck(i2s_bclk),
	.lrclk(i2s_lrclk),
	.dat(i2s_dat)
);
`endif

// Button input
wire btn_pressed;
debounce btn_db(
	.clk(clk),
	.button(~btn),
	.btn_out(btn_pressed)
);

//reg [2:0] int_lvl;
assign IPL = { ~btn_pressed, ~btn_pressed, ~btn_pressed };
assign AVEC = 1'b1;

assign i2s_bclk = btn_pressed;

// Generate an interrupt when the button is pressed
/*
always @(posedge clk) begin
	if (btn_pressed == 1'b1) begin
		int_lvl <= 3'b111;
	end else begin
		int_lvl <= 3'b000;
	end
end
*/

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

reg [3:0] count;

localparam	START = 0,
		GET_DATA = 1,
		WAIT_DATA = 2,
		START_TA = 3,
		FINISH_TA = 4,
		RAM_ACCESS = 5,
		ILLEGAL_ACCESS = 6,
		ILLEGAL_ACCESS_END = 7;

localparam FLASH_PAGE = 8'h04;

wire rom_sel;
assign rom_sel = (addr[31:28] == 4'h0);

wire uart_sel;
assign uart_sel = (addr[31:28] == 4'h2);

wire ram_sel;
assign ram_sel = (addr[31:28] == 4'h3);

wire fpga_sel;
assign fpga_sel = (addr[31:28] == 4'h8);

wire vector_access = ( (tip == 0) && (addr == 32'hFFFFFFFF) );

wire rom_access = ( (tip == 0) && (rom_sel == 1) );
wire ram_access = ( (tip == 0) && (ram_sel == 1) );	// 55nS
wire uart_access = ( (tip == 0) && (uart_sel == 1) );
wire illegal_access = (!rom_access && !ram_access && !uart_access);

wire resiz_access = ( ram_access || uart_access );

// Do the following for non-rom accesses:
//
// Assert RESIZ_CS
// Assign RESIZ_DS to the selected peripheral's CS line and start counting
// After the count expires, assert DSACKn for two CLK falling edges
// Deassert DSACKn

wire COM_CS, RAM_CS, RESIZ_CS;
assign COM_CS = uart_access ? ~RESIZ_DS : 1'b0;
assign RAM_CS = ram_access ? ~RESIZ_DS : 1'b0;

reg [1:0] resiz_count;
assign RESIZ_CS = ts && (uart_access || ram_access);

always @(posedge clk or negedge rst) begin
	if (~rst) begin
		state <= START;
		i_ta <= 1'b0;
		i_tea <= 0;
		d_oe <= 1;
		flash_stb <= 0;
		flash_cyc <= 0;
		flash_sel <= 0;
		ram_ack <= 0;
		resiz_count <= 0;
		count <= 0;
	end else begin
		case (state)
			START: begin
				i_ta <= 0;
				i_tea <= 0;
				d_oe <= 1;
				flash_stb <= 0;
				flash_cyc <= 0;
				flash_sel <= 0;
				ram_ack <= 0;
				count <= 0;

				if( vector_access == 1'b1 && ts == 1 ) begin
					state <= START_TA;
				end else if( rom_access == 1'b1 && ts == 1 ) begin
					flash_addr <= { (addr[23:16] + FLASH_PAGE ), addr[15:2] };
					state <= GET_DATA;
				end else if( ram_access == 1'b1 && ts == 1 ) begin
					case (siz)
						2'b11,
						2'b00: begin
							resiz_count <= 2'b01;	// two accesses
						end
						2'b10: begin
							resiz_count <= 2'b00;	// one access
						end
						2'b01: begin
							resiz_count <= 2'b00;	// one access
						end
					endcase
					state <= RAM_ACCESS;
					/*
				end else if ( illegal_access == 1'b1 && ts == 1 ) begin
					state <= ILLEGAL_ACCESS;
					*/
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
			RAM_ACCESS: begin
				count <= count + 1;
				if( count == 3'b101 ) begin
					ram_ack <= 1;
				end
				if( count == 3'b111 ) begin
					// Done
					ram_ack <= 0;

					// If this is the last transfer
					if( resiz_count == 2'b00 ) begin
						state <= START;
					end else begin
						// Else, reset counters
						resiz_count <= resiz_count - 1;
						count <= -1;
					end
				end
			end
			ILLEGAL_ACCESS: begin
				i_tea <= 1;
				state <= ILLEGAL_ACCESS_END;
			end
			ILLEGAL_ACCESS_END: begin
				i_tea <= 0;
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
