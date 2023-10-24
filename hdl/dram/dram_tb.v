`timescale 1ns/1ps

module dram_tb();

localparam DURATION = 10000;

reg clk;
reg reset;

initial begin
	clk = 1'b0;
	forever #15.15 clk = ~clk;
end

initial begin
	// Create simulation output file 
	$dumpfile("dram_tb.vcd");
	$dumpvars(0, dram_tb);
        
	// Wait for given amount of time for simulation to complete
	#(DURATION)
        
	// Notify and end simulation
	$display("Finished!");
	$finish;
end

endmodule
