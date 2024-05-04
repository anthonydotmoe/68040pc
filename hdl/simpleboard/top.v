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

assign COM_IACK = 0;

reg ram_ack;
wire [1:0] DSACK;
assign DSACK[0] = 1'b1;
assign DSACK[1] = ~ram_ack;

// End assign

// --- Debug lines ---
`ifdef DEBUG
assign i2s_bclk = 1'b0;
assign i2s_lrclk = 1'b0;
assign i2s_dat = 1'b0;
`elsif SOUND

// Noisemaker
i2s_tx sound(
	.clk(clk),
	.sck(i2s_bclk),
	.lrclk(i2s_lrclk),
	.dat(i2s_dat)
);

`else
assign i2s_bclk = 1'b0;
assign i2s_lrclk = 1'b0;
assign i2s_dat = 1'b0;
`endif

// A/D Buffer
reg [31:0] addr;
reg [31:0] d;
reg d_oe;

// Transfer Ack
reg i_tea;
assign tea = ~i_tea;
reg i_ta;
assign ta = ~i_ta;

// Button input
wire btn_pressed;
debounce btn_db(
	.clk(clk),
	.button(~btn),
	.btn_out(btn_pressed)
);

// DFF for TS
reg i_ts;
always @(posedge clk) i_ts <= !ts;

//reg [2:0] int_lvl;

wire [3:0] com_btn_ipl;
assign com_btn_ipl[2] = ~(~COM_IRQ | btn_pressed);
assign com_btn_ipl[1:0] = { ~btn_pressed, ~btn_pressed };

assign IPL[2:0] = com_btn_ipl & fpga_ipl;
assign AVEC = 1'b1;

// ROM reader signals
wire [21:0] flash_addr;
wire [31:0] flash_data;
assign flash_addr = { (addr[23:16] + FLASH_PAGE ), addr[15:2] };
wire flash_stb, flash_ack;
assign flash_stb = rom_sel && i_ts;

// Instantiate ROM reader
rom rom_reader(
	.clk(clk),
	.rst(rst),

	.rom_stb(flash_stb),
	.rom_ack(flash_ack),
	.rom_addr(flash_addr),
	.rom_odata(flash_data),

	.spi_ss(spi_ss),
	.spi_sck(spi_sck),
	.spi_mosi(spi_mosi),
	.spi_miso(spi_miso),
	.spi_io2(spi_io2),
	.spi_io3(spi_io3)
);

wire fpga_stb, fpga_ack;
wire [2:0] fpga_ipl;
wire [7:0] fpga_data;
assign fpga_stb = fpga_sel && i_ts;
assign fpga_data = 8'h00;

// Instantiate FPGA-CPU interface
fpga_int fpga_interface(
	.clk(clk),
	.rst(rst),

	.fpga_stb(fpga_stb),
	.fpga_ack(fpga_ack),
	.fpga_addr(addr[3:0]),
	.fpga_data(fpga_data),
	.fpga_odata(),

	.out_ipl(fpga_ipl)
);

reg [2:0] state;
reg [3:0] count;

localparam	START = 0,
		WAIT_ROM = 1,
		WAIT_FPGA = 2,
		START_TA = 3,
		FINISH_TA = 4,
		RAM_ACCESS = 5,
		ILLEGAL_ACCESS = 6,
		ILLEGAL_ACCESS_END = 7;

localparam FLASH_PAGE = 8'h04;

wire rom_sel, uart_sel, ram_sel, fpga_sel;
assign rom_sel = (addr[31:28] == 4'h0);
assign uart_sel = (addr[31:28] == 4'h2);
assign ram_sel = (addr[31:28] == 4'h3);
assign fpga_sel = (addr[31:28] == 4'h8);

wire rom_access = ( (tip == 0) && (rom_sel == 1) );
wire uart_access = ( (tip == 0) && (uart_sel == 1) );
wire ram_access = ( (tip == 0) && (ram_sel == 1) );	// 55nS
wire fpga_access = ( (tip == 0) && (fpga_sel == 1) );
wire vector_access = ( (tip == 0) && (addr == 32'hFFFFFFFF) );
wire illegal_access = &{ !rom_access, !uart_access, !ram_access, !fpga_access, !vector_access };

wire resiz_access = ( ram_access || uart_access );

// Do the following for 68150 accesses:
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
		ram_ack <= 0;
		resiz_count <= 0;
		count <= 0;
	end else begin
		case (state)
			START: begin
				i_ta <= 0;
				i_tea <= 0;
				d_oe <= 1;
				ram_ack <= 0;
				count <= 0;

				if( vector_access == 1'b1 && ts == 1 ) begin
					state <= START_TA;
				end else if( rom_access == 1'b1 && ts == 1 ) begin
					state <= WAIT_ROM;
				end else if( ram_access == 1'b1 && ts == 1 ) begin
					resiz_count <= (siz[0] && siz[1])? 2'b01 : 2'b00;
					state <= RAM_ACCESS;
				/*	
				end else if ( illegal_access == 1'b1 ) begin
					state <= ILLEGAL_ACCESS;
				*/
			        end else if( fpga_access == 1'b1 && ts == 1 ) begin
					state <= WAIT_FPGA;
				end else begin
					state <= START;
				end
			end
			WAIT_ROM: begin
				if( flash_ack == 1'b1 ) begin
					d <= flash_data;
					state <= START_TA;
				end
			end
			WAIT_FPGA: begin
				if( fpga_ack == 1'b1 ) begin
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
