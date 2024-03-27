`timescale 1ns/1ps

module flash_tb ();

reg clk;
reg reset;

flash dut(
	.clk(clk), .rst(reset)
);

parameter DURATION = 2000;

initial begin
	clk = 1'b0;
	forever begin
		#15 clk = ~clk;
	end
end

initial begin
	reset = 1'b1;
	#10
	reset = 1'b0;
	#10
	reset = 1'b1;
end

initial begin
	$dumpfile("flash_tb.vcd");
	$dumpvars(0, flash_tb);

	#(DURATION) $display("End");
	$finish;
end


endmodule
