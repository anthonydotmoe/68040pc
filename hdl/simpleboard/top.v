//`define SOUND
`define DEBUG

(* top *)
module top (
	input	clk,		// 68040 BCLK
	input	rst,
	input	btn,
	output	led,

	output	d_dir,		// D[31:0] 74ALVC16425 DIR
	output	d_oe,		// D[31:0] 74ALVC16425 OE

	input	[31:0]	a,	// A[31:0] direct from CPU
	inout	[31:0]	d,	// D[31:0] FPGA <-> 74ALVC16425 <-> CPU

	output	dbg0,
	output	dbg1,
	output	dbg2,

	input	ts,			// Transfer Start
	output	ta,			// Transfer Acknowledge
	output	tea,		// Transfer Error Acknowledge
	input	tip,		// Transfer In Progress
	output	tci,		// Transfer Cache Inhibit
	output	tbi,		// Transfer Burst Inhibit
	input	[1:0]	tt,	// Transfer Type
	input	[2:0]	tm,	// Transfer Modifier
	input	[1:0]	siz,// Transfer Size

	input	rw,

	output	[1:0]	DSACK,	// FPGA -> 74LVC07 -> 68150 DSACK
	input		RESIZ_DS,	// 68150 -> DS
	output		RESIZ_CS,	// FPGA -> 74AHCT04 -> 68150 CS

	output		COM_CS,		// FPGA -> 74AHCT04 -> DUART CS
	input		COM_IRQ,	// DUART -> FPGA
	output		COM_IACK,	// FPGA -> 74AHCT04 -> DUART IACK

	output		RAM_CS,		// FPGA -> 74AHCT04 -> RAM CS

	output	[2:0]	IPL,	// FPGA -> 74LVC07 -> 68040 IPL
	output		AVEC,		// FPGA -> 74AHCT04 -> 68040 AVEC

	output	spi_ss,
	output	spi_sck,
	output	spi_mosi,
	input	spi_miso,
	output	spi_io2,
	output	spi_io3
);

// Assign default states -------------------------------------------------------
assign tci = 1;
assign tbi = 0;

assign COM_IACK = 0;

// Debug lines -----------------------------------------------------------------
assign dbg0 = a[29];
assign dbg1 = a[30];
assign dbg2 = a[31];

// Addr Buffer -----------------------------------------------------------------
reg [31:0] addr;

// Data transceiver ------------------------------------------------------------
wire [31:0] data_in;
reg [31:0] data_out;
reg d_oe;
wire d_dir;

// rw is HIGH for DEVICE -> CPU
//        LOW for    CPU -> DEVICE
//
// d_dir needs to be  HIGH for FPGA -> CPU
//                     LOW for CPU  -> FPGA
assign d_dir = rw;

SB_IO #(
	.PIN_TYPE(6'b1010_01),
	.PULLUP(1'b1)
) data_io [31:0] (
	.PACKAGE_PIN(d[31:0]),
	.OUTPUT_ENABLE(rw),
	.D_OUT_0(data_out[31:0]),
	.D_IN_0(data_in[31:0])
);

// Transfer Ack ----------------------------------------------------------------
reg i_tea;
assign tea = ~i_tea;
reg i_ta;
assign ta = ~i_ta;

// Button input ----------------------------------------------------------------
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

wire [2:0] com_btn_ipl;
assign com_btn_ipl[2] = ~(~COM_IRQ | btn_pressed);
assign com_btn_ipl[1:0] = { ~btn_pressed, ~btn_pressed };

assign IPL[2:0] = com_btn_ipl & fpga_ipl;
assign AVEC = 1'b1;

// ROM reader signals
localparam FLASH_PAGE = 8'h04;
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
	.fpga_data(data_in[31:24]),
	.fpga_odata(),

	.out_ipl(fpga_ipl)
);

reg [2:0] state;

localparam	START = 0,
		WAIT_ROM = 1,
		WAIT_FPGA = 2,
		START_TA = 3,
		FINISH_TA = 4,
		ILLEGAL_ACCESS = 5,
		ILLEGAL_ACCESS_END = 6;


wire rom_sel, uart_sel, ram_sel, fpga_sel;
assign rom_sel = (addr[31:28] == 4'h0);
assign uart_sel = (addr[31:28] == 4'h2);
assign ram_sel = (addr[31:28] == 4'h4);
assign fpga_sel = (addr[31:28] == 4'h6);

wire rom_access = ( (tip == 0) && (rom_sel == 1) );
wire uart_access = ( (tip == 0) && (uart_sel == 1) );
wire ram_access = ( (tip == 0) && (ram_sel == 1) );	// 55nS
wire fpga_access = ( (tip == 0) && (fpga_sel == 1) );
wire vector_access = ( (tip == 0) && (addr == 32'hFFFFFFFF) );
wire illegal_access = ( (tip == 0) && &{ !rom_access, !uart_access, !ram_access, !fpga_access, !vector_access } );

// Do the following for 68150 accesses:
//
// Assert RESIZ_CS
// Assign RESIZ_DS to the selected peripheral's CS line and start counting
// After the count expires, assert DSACKn for two CLK falling edges
// Deassert DSACKn
reg [2:0] ram_wait_cnt;
reg       ram_busy;
reg       ram_ack;

reg       ds_prev;
wire      ds_now  = RESIZ_DS; // active low from 68150
wire      ds_fall = ds_prev & ~ds_now;

localparam integer RAM_WS     = 3'd1; // 60ns
localparam integer RAM_WS_END = RAM_WS + 3'd1;

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		ds_prev      <= 1'b1;
		ram_wait_cnt <= 3'b000;
		ram_busy     <= 1'b0;
		ram_ack      <= 1'b0;
	end else begin
		ds_prev <= ds_now;

		if (!ram_busy) begin
			// Start a new local access when 68150 asserts DS to RAM
			if (!ds_now && ds_fall && ram_sel) begin
				ram_busy     <= 1'b1;
				ram_wait_cnt <= 3'b000;
				ram_ack      <= 1'b0;
			end
		end else begin
			// In a local RAM access wait
			ram_wait_cnt <= ram_wait_cnt + 1;

			if (ram_wait_cnt == RAM_WS) begin
				ram_ack <= 1'b1;
			end

			if (ram_wait_cnt == RAM_WS_END || ds_now) begin
				// finish this local access
				ram_ack  <= 1'b0;
				ram_busy <= 1'b0;
			end
		end
	end
end

assign DSACK[0] = 1'b1;
assign DSACK[1] = ~ram_ack;

wire COM_CS, RAM_CS, RESIZ_CS;
assign COM_CS = uart_access ? ~RESIZ_DS : 1'b0;
assign RAM_CS = ram_access ? ~RESIZ_DS : 1'b0;

assign RESIZ_CS = ts && (uart_access || ram_access);

always @(posedge clk or negedge rst) begin
	if (~rst) begin
		state <= START;
		i_ta <= 1'b0;
		i_tea <= 0;
		d_oe <= 1;
	end else begin
		case (state)
			START: begin
				i_ta <= 0;
				i_tea <= 0;
				d_oe <= 1;

				if( vector_access == 1'b1 && ts == 1 ) begin
					state <= START_TA;
				end else if( rom_access == 1'b1 && ts == 1 ) begin
					state <= WAIT_ROM;
				end else if ( illegal_access == 1'b1 ) begin
					state <= ILLEGAL_ACCESS;
			    end else if( fpga_access == 1'b1 && ts == 1 ) begin
					d_oe <= 0;
					state <= WAIT_FPGA;
				end else begin
					state <= START;
				end
			end
			WAIT_ROM: begin
				if( flash_ack == 1'b1 ) begin
					data_out <= flash_data;
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

// Latch address when TS is going low
reg ts_prev;
always @(posedge clk or negedge rst) begin
	if (!rst) begin
		ts_prev <= 1'b1;
		addr    <= 32'h00000000;
	end else begin
		ts_prev <= ts;

		// TS falling edge: valid address for new bus cycle
		if (ts_prev == 1'b1 && ts == 1'b0)
			addr <= a;
	end
end

// Blinky lights ---------------------------------------------------------------

// Event: Read address 0x03 from DUART
wire blink_event = ((uart_sel == 1'b1) &&
                    (addr[3:0] == 4'b0011) &&
                    (rw == 1'b1));

// Timing
localparam integer OFF_TICKS   = 23'd2_000_000;  // ~60 ms at 33 MHz
localparam integer TOTAL_TICKS = 23'd4_000_000;  // total cycle time (~120 ms)

// How many blink cycles we can queue up
localparam integer BLINK_QUEUE_BITS = 4;         // up to 15 pending events

// State
reg        blink_active;    // 0 = idle, 1 = currently in a blink cycle
reg [22:0] blink_count;
reg        blink_event_d;   // for edge detection
reg [BLINK_QUEUE_BITS-1:0] blink_queue;  // pending blink cycles

// edge-detect blink_event so we only trigger on rising edges.
wire blink_event_edge = blink_event & ~blink_event_d;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        blink_active   <= 1'b0;
        blink_count    <= 23'd0;
        blink_event_d  <= 1'b0;
        blink_queue    <= {BLINK_QUEUE_BITS{1'b0}};
    end else begin
        // Capture previous value for edge detection
        blink_event_d <= blink_event;

        // On every rising edge of blink_event, enqueue a blink cycle
        // (saturating at the max representable value).
        if (blink_event_edge) begin
            if (blink_queue != {BLINK_QUEUE_BITS{1'b1}}) begin
                blink_queue <= blink_queue + 1'b1;
            end
        end

        if (!blink_active) begin
            // Idle: if there are queued events, start a new cycle
            if (blink_queue != {BLINK_QUEUE_BITS{1'b0}}) begin
                blink_active <= 1'b1;
                blink_count  <= 23'd0;
                blink_queue  <= blink_queue - 1'b1;
            end
        end else begin
            // In an off+on cycle
            blink_count <= blink_count + 1'b1;

            if (blink_count == (TOTAL_TICKS - 1)) begin
                blink_active <= 1'b0;   // done; go back to idle
            end
        end
    end
end


// Logical LED behavior (before polarity inversion):
//
// - When idle (blink_active = 0): LED is ON (steady).
// - During the cycle (blink_active = 1):
//     * First OFF_TICKS cycles: LED OFF
//     * Remaining (TOTAL_TICKS - OFF_TICKS) cycles: LED ON
//
wire led_logical =
    (!blink_active)                  ? 1'b1 :   // idle: ON
    (blink_count < OFF_TICKS)        ? 1'b0 :   // first phase: OFF
                                       1'b1;    // second phase: ON

// Flip polarity for the physical LED:
// If the board LED is active-low, then:
//   led = 0 -> LED ON
//   led = 1 -> LED OFF
assign led = ~led_logical;


endmodule
