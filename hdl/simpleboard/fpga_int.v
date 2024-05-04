/* FPGA interface for 68040 */
module fpga_int(
	input clk,
	input rst,

	input fpga_stb,
	output fpga_ack,
	input [3:0] fpga_addr,
	input [7:0] fpga_data,
	output [31:0] fpga_odata,

	// Interrupt lines
	output [2:0] out_ipl
);

assign fpga_odata = 0;


reg waitstate, fpga_ack;

// State machine just ACKs after one cycle
always @(posedge clk) begin
	if(~rst) begin
		// Reset logic here
		waitstate <= 0;
		fpga_ack <= 0;
	end else begin
		if (fpga_stb == 1) begin
			fpga_ack <= 0;
			waitstate <= 1;
		end else if (waitstate == 1) begin
			fpga_ack <= 1;
			waitstate <= 0;
		end
	end
end

// IPL lines active when interrupt register is selected
wire int_sel = ( fpga_addr == 4'h4 && fpga_stb );
assign out_ipl[0] = ~( int_sel && fpga_data[0] );
assign out_ipl[1] = ~( int_sel && fpga_data[1] );
assign out_ipl[2] = ~( int_sel && fpga_data[2] );

endmodule
