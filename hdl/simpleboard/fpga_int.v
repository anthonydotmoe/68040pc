/* FPGA interface for 68040 */
module fpga_int(
	input clk,
	input rst,

	input fpga_stb,
	output fpga_ack,
	input fpga_rw,
	input [3:0] fpga_addr,
	input [7:0] fpga_data,
	output [31:0] fpga_odata,

	// Interrupt lines
	output [2:0] out_ipl,
	output led_state,
	output uart_tx
);

reg [2:0] out_ipl;
reg led_state;

reg waitstate, fpga_ack;

localparam F_LED = 4'h0;
localparam F_INT = 4'h4;
localparam F_UART_TX = 4'h8;
localparam F_UART_SR = 4'hC;

localparam integer UART_CLK_HZ = 33000000;
localparam integer UART_BAUD = 115200;
localparam [8:0] UART_DIV = UART_CLK_HZ / UART_BAUD;

// State machine just ACKs after one cycle
always @(posedge clk or negedge rst) begin
	if(~rst) begin
		// Reset logic here
		waitstate <= 0;
		fpga_ack <= 0;
	end else begin
		fpga_ack <= 0;

		if (fpga_stb == 1) begin
			waitstate <= 1;
		end else if (waitstate == 1) begin
			fpga_ack <= 1;
			waitstate <= 0;
		end
	end
end

wire fpga_write;
assign fpga_write = waitstate && !fpga_rw;

always @(posedge clk or negedge rst) begin
	if(~rst) begin
		out_ipl <= 0;
		led_state <= 0;
	end else begin
		if (fpga_write && fpga_addr == F_INT) begin
			out_ipl <= ~fpga_data[2:0];
		end

		if (fpga_write && fpga_addr == F_LED) begin
			led_state <= fpga_data[0];
		end
	end
end

// 8-N-1 TX-only UART.  Writes while busy are ignored.
reg [9:0] uart_shift;
reg [3:0] uart_bits_left;
reg [8:0] uart_baud_cnt;

wire uart_busy;
assign uart_busy = (uart_bits_left != 4'd0);
assign uart_tx = uart_busy ? uart_shift[0] : 1'b1;

always @(posedge clk or negedge rst) begin
	if(~rst) begin
		uart_shift <= 10'h3FF;
		uart_bits_left <= 4'd0;
		uart_baud_cnt <= 9'd0;
	end else begin
		if (fpga_write && fpga_addr == F_UART_TX && !uart_busy) begin
			uart_shift <= { 1'b1, fpga_data, 1'b0 };
			uart_bits_left <= 4'd10;
			uart_baud_cnt <= UART_DIV - 9'd1;
		end else if (uart_busy) begin
			if (uart_baud_cnt == 9'd0) begin
				uart_shift <= { 1'b1, uart_shift[9:1] };
				uart_bits_left <= uart_bits_left - 4'd1;
				uart_baud_cnt <= UART_DIV - 9'd1;
			end else begin
				uart_baud_cnt <= uart_baud_cnt - 9'd1;
			end
		end
	end
end

assign fpga_odata =
	(fpga_addr == F_LED) ? { 7'b0, led_state, 24'b0 } :
	(fpga_addr == F_INT) ? { 5'b0, ~out_ipl, 24'b0 } :
	(fpga_addr == F_UART_SR) ? { 7'b0, uart_busy, 24'b0 } :
			       32'b0;

endmodule
