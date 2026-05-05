`timescale 1ns/1ps

module debounce_tb;

reg clk = 0;
reg noisy = 0;
wire clean;

debounce dut (
    .button(noisy),
    .clk(clk),
    .btn_out(clean)
);

always #15 clk = ~clk;

initial begin
    $dumpfile("output/debounce_tb.vcd");
    $dumpvars(0, debounce_tb);

    // Simulate switch bounce
    noisy <= 1; @(negedge clk);
    noisy <= 0; @(negedge clk);
    noisy <= 1; @(negedge clk);
    noisy <= 1; @(negedge clk);
    noisy <= 1; @(posedge clk);
    noisy <= 0; @(posedge clk);
    noisy <= 1; @(negedge clk);
    noisy <= 0; @(negedge clk);
    noisy <= 0; @(posedge clk);
    noisy <= 0; @(negedge clk);
    noisy <= 1; @(negedge clk);
    noisy <= 0; @(negedge clk);
    noisy <= 1; @(negedge clk);
    noisy <= 0; @(negedge clk);
    noisy <= 0; @(negedge clk);
    noisy <= 0; @(posedge clk);
    noisy <= 1; @(negedge clk);
    noisy <= 0; @(negedge clk);
    noisy <= 1; @(negedge clk);
    noisy <= 0; @(negedge clk);
    noisy <= 1; @(posedge clk);
    noisy <= 0; @(negedge clk);
    noisy <= 1; @(negedge clk);
    noisy <= 0; @(negedge clk);
    noisy <= 1;

    // Let debounce logic settle
    repeat (1000000) @(negedge clk);

    if (clean !== 1'b1) begin
        $display("FAIL: clean did not become 1");
        $finish;
    end

    $display("PASS");
    $finish;
end

endmodule
