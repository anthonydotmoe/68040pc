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
	output led_state
);

reg [2:0] out_ipl;
reg led_state;

reg waitstate, fpga_ack;

localparam F_LED = 4'h0;
localparam F_INT = 4'h4;

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

assign fpga_odata =
	(fpga_addr == F_LED) ? { 7'b0, led_state, 24'b0 } :
	(fpga_addr == F_INT) ? { 5'b0, ~out_ipl, 24'b0 } :
			       32'b0;

endmodule
