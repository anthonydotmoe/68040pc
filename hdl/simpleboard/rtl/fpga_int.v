/* FPGA interface for 68040 */
module fpga_int(
    input clk,
    input rst,

    input fpga_stb,
    output reg fpga_ack,
    input fpga_rw,
    input [4:0] fpga_addr,
    input [7:0] fpga_data,
    output [31:0] fpga_odata,

    // Interrupt lines
    output reg [2:0] out_ipl,
    output reg led_state,
    output uart_tx,
    input uart_rx
);

reg waitstate;

localparam F_LED = 5'h00;
localparam F_INT = 5'h04;
localparam F_UART_TX = 5'h08;
localparam F_UART_SR = 5'h0C;
localparam F_UART_RX = 5'h10;

localparam integer UART_CLK_HZ = 33000000;
localparam integer UART_BAUD = 115200;
localparam [8:0] UART_DIV = UART_CLK_HZ / UART_BAUD;
localparam [4:0] UART_RX_DIV =
    (UART_CLK_HZ + (UART_BAUD * 8)) / (UART_BAUD * 16);

// State machine just ACKs after one cycle
always @(posedge clk or negedge rst) begin
    if(~rst) begin
        // Reset logic here
        waitstate <= 0;
        fpga_ack <= 0;
    end else begin
        fpga_ack <= 0;

        if (fpga_stb == 1) begin
            //waitstate <= 1;
        //end else if (waitstate == 1) begin
            fpga_ack <= 1;
            //waitstate <= 0;
        end
    end
end

wire fpga_write;
//assign fpga_write = waitstate && !fpga_rw;
assign fpga_write = fpga_ack && !fpga_rw;

wire fpga_read;
//assign fpga_read = waitstate && fpga_rw;
assign fpga_read = fpga_ack && fpga_rw;

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

// 8-N-1 UART TX.  Writes while busy are ignored.
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

// 8-N-1 UART RX, 16x oversampled.  No FIFO; new bytes are dropped while
// unread data is pending.
reg uart_rx_meta;
reg uart_rx_sync;

always @(posedge clk or negedge rst) begin
    if(~rst) begin
        uart_rx_meta <= 1'b1;
        uart_rx_sync <= 1'b1;
    end else begin
        uart_rx_meta <= uart_rx;
        uart_rx_sync <= uart_rx_meta;
    end
end

localparam RX_IDLE = 2'd0;
localparam RX_START = 2'd1;
localparam RX_DATA = 2'd2;
localparam RX_STOP = 2'd3;

reg [1:0] uart_rx_state;
reg [4:0] uart_rx_div_cnt;
reg [3:0] uart_rx_sample_cnt;
reg [2:0] uart_rx_bit_cnt;
reg [7:0] uart_rx_shift;
reg [7:0] uart_rx_data;
reg uart_rx_rdy;

always @(posedge clk or negedge rst) begin
    if(~rst) begin
        uart_rx_state <= RX_IDLE;
        uart_rx_div_cnt <= 5'd0;
        uart_rx_sample_cnt <= 4'd0;
        uart_rx_bit_cnt <= 3'd0;
        uart_rx_shift <= 8'd0;
        uart_rx_data <= 8'd0;
        uart_rx_rdy <= 1'b0;
    end else begin
        if (fpga_read && fpga_addr == F_UART_RX) begin
            uart_rx_rdy <= 1'b0;
        end

        case (uart_rx_state)
            RX_IDLE: begin
                uart_rx_div_cnt <= 5'd0;
                uart_rx_sample_cnt <= 4'd0;

                if (!uart_rx_sync) begin
                    uart_rx_state <= RX_START;
                end
            end
            RX_START: begin
                if (uart_rx_div_cnt == UART_RX_DIV - 5'd1) begin
                    uart_rx_div_cnt <= 5'd0;

                    if (uart_rx_sample_cnt == 4'd7) begin
                        if (!uart_rx_sync) begin
                            uart_rx_sample_cnt <= 4'd0;
                            uart_rx_bit_cnt <= 3'd0;
                            uart_rx_state <= RX_DATA;
                        end else begin
                            uart_rx_state <= RX_IDLE;
                        end
                    end else begin
                        uart_rx_sample_cnt <= uart_rx_sample_cnt + 4'd1;
                    end
                end else begin
                    uart_rx_div_cnt <= uart_rx_div_cnt + 5'd1;
                end
            end
            RX_DATA: begin
                if (uart_rx_div_cnt == UART_RX_DIV - 5'd1) begin
                    uart_rx_div_cnt <= 5'd0;

                    if (uart_rx_sample_cnt == 4'd15) begin
                        uart_rx_shift <= { uart_rx_sync, uart_rx_shift[7:1] };
                        uart_rx_sample_cnt <= 4'd0;

                        if (uart_rx_bit_cnt == 3'd7) begin
                            uart_rx_state <= RX_STOP;
                        end else begin
                            uart_rx_bit_cnt <= uart_rx_bit_cnt + 3'd1;
                        end
                    end else begin
                        uart_rx_sample_cnt <= uart_rx_sample_cnt + 4'd1;
                    end
                end else begin
                    uart_rx_div_cnt <= uart_rx_div_cnt + 5'd1;
                end
            end
            RX_STOP: begin
                if (uart_rx_div_cnt == UART_RX_DIV - 5'd1) begin
                    uart_rx_div_cnt <= 5'd0;

                    if (uart_rx_sample_cnt == 4'd15) begin
                        if (uart_rx_sync && !uart_rx_rdy) begin
                            uart_rx_data <= uart_rx_shift;
                            uart_rx_rdy <= 1'b1;
                        end

                        uart_rx_state <= RX_IDLE;
                    end else begin
                        uart_rx_sample_cnt <= uart_rx_sample_cnt + 4'd1;
                    end
                end else begin
                    uart_rx_div_cnt <= uart_rx_div_cnt + 5'd1;
                end
            end
        endcase
    end
end

assign fpga_odata =
    (fpga_addr == F_LED) ? { 7'b0, led_state, 24'b0 } :
    (fpga_addr == F_INT) ? { 5'b0, ~out_ipl, 24'b0 } :
    (fpga_addr == F_UART_SR) ? { 6'b0, uart_rx_rdy, ~uart_busy, 24'b0 } :
    (fpga_addr == F_UART_RX) ? { uart_rx_data, 24'b0 } :
                   32'b0;

endmodule
