(* top *)
module flash (
	input	clk,
	input	rst,
	output	led,

	output	d_dir,
	output	d_oe,

	input	[31:0]	a,
	output	[31:0]	d,

	output	dbg1,
	output	dbg2,
	output	dbg3,

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


assign led = ~rw;

reg i_ta;

assign ta = ~i_ta;

// Yellow
assign dbg1 = spi_ss;
// Blue
assign dbg2 = a[2];
// Purple
assign dbg3 = ts;

wire rom_sel;
assign rom_sel = (addr[31:28] == 4'b0000);


reg d_oe;
reg flash_stb, flash_cyc;
wire [31:0] flash_data;
wire flash_ack, flash_stall;
reg flash_reset;
//wire flash_reset = ~rst;

wire spi_sck_en;
reg [21:0] flash_addr; // 24 bits minus two for long word reads
oclkddr spi_ddr_sck(clk, {!spi_sck_en, 1'b1}, spi_sck);

reg [3:0] flash_sel, flash_c_sel;

wire flash_c_stall, flash_c_ack;
wire [31:0] flash_c_data, flash_idata;
reg flash_c_stb, flash_c_cyc, flash_c_we;
reg [31:0] flash_c_idata;

assign flash_idata = 0;

spixpress #(
	.OPT_CFG(1'b1),
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

	.i_cfg_cyc(flash_c_cyc),
	.i_cfg_stb(flash_c_stb),
	.i_cfg_we(flash_c_we),
	.i_cfg_data(flash_c_idata),
	.i_cfg_sel(flash_c_sel),
	.o_cfg_stall(flash_c_stall),
	.o_cfg_ack(flash_c_ack),
	.o_cfg_data(flash_c_data),

	.o_spi_cs_n(spi_ss),
	.o_spi_sck(spi_sck_en),
	.o_spi_mosi(spi_mosi),
	.i_spi_miso(spi_miso)
);

reg [3:0] state;

//reg [3:0] count;

localparam	START = 0,
		SEND_WAKE = 1,
		WAIT_WAKE1 = 2,
		WAIT_WAKE2 = 3,
		GET_DATA = 4,
		WAIT_DATA = 5,
		START_TA = 6,
		FINISH_TA = 7;

localparam FLASH_PAGE = 8'h04;

reg flash_awake;
initial flash_awake = 0;

reg [7:0] wake_wait;
initial wake_wait = 0;

always @(posedge clk or negedge rst) begin
	if (~rst) begin
		flash_awake <= 0;
		state <= START;
		i_ta <= 1'b0;
		d_oe <= 1;
		flash_stb <= 0;
		flash_cyc <= 0;
		flash_sel <= 0;
		flash_c_stb <= 0;
		flash_c_cyc <= 0;
		flash_c_sel <= 0;
		flash_c_idata <= 32'b0;
		flash_c_we <= 0;
		flash_reset <= 1;
		wake_wait <= 0;
	end else begin
		case (state)
			START: begin
				i_ta <= 0;
				d_oe <= 1;
				flash_stb <= 0;
				flash_cyc <= 0;
				flash_sel <= 0;
				flash_c_stb <= 0;
				flash_c_cyc <= 0;
				flash_c_sel <= 0;
				flash_c_we <= 0;
				flash_reset <= 0;

				if( (tip == 0) && (rom_sel == 1) ) begin
					if( flash_awake == 0 ) begin
						flash_c_idata[7:0] <= 8'hAB;	// Wake command
						state <= SEND_WAKE;
					end else begin
						flash_addr <= { (addr[23:16] + FLASH_PAGE ), addr[15:2] };
						state <= GET_DATA;
					end
				end

				state <= START;
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
			SEND_WAKE: begin
				flash_c_cyc <= 1;
				flash_c_stb <= 1;
				flash_c_we <= 1;
				state <= WAIT_WAKE1;
			end
			WAIT_WAKE1: begin
				flash_c_stb <= 0;
				state <= WAIT_WAKE1;

				if( flash_c_ack == 1 ) begin
					flash_c_cyc <= 0;
					flash_c_we <= 0;
					wake_wait <= 0;
					state <= WAIT_WAKE2;
				end
			end
			WAIT_WAKE2: begin
				if (wake_wait == 8'hFF) begin
					flash_awake <= 1;
					state <= START;
				end else begin
					wake_wait <= wake_wait + 1;
					state <= WAIT_WAKE2;
				end
			end
		endcase
	end
end

// Latch address when TS is asserted
always @(posedge clk) begin
	if (ts == 1'b0)
		addr <= a;
end

endmodule
