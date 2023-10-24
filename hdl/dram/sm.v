//------------------------------------------------------------------------------
//
// DRAM Controller State machine
//
//------------------------------------------------------------------------------

module sm(
	input clk,
	input nRESET

	// TODO: ...
);

// Asynchronous versions of outputs
reg a_refack;

// internal signals
reg		refreq;		// Refresh request
wire		tc;		// Refresh counter equals limit
reg [8:0]	q;		// Refresh counter
reg		refack;		// Refresh Acknowledge
reg [3:0]	state, nstate;	// Current state, next state

// states
parameter [3:0] idle	= 4'b0000;
parameter [3:0] rw1	= 4'b0001;
parameter [3:0] rw2	= 4'b0010;
parameter [3:0] rw3	= 4'b0011;
parameter [3:0] cbr1	= 4'b0100;
parameter [3:0] cbr2	= 4'b0101;
parameter [3:0] cbr3	= 4'b0110;
parameter [3:0] cbr4	= 4'b0111;
parameter [3:0] prechg	= 4'b1000;
parameter [3:0] page1	= 4'b1001;
parameter [3:0] page2	= 4'b1010;
parameter [3:0] page3	= 4'b1011;
parameter [3:0] dummy1	= 4'b1100;
parameter [3:0] dummy2	= 4'b1101;
parameter [3:0] dummy3	= 4'b1110;
parameter [3:0] dummy4	= 4'b1111;

// The DRAM controller is implemented as two finite-state machines. The first
// machine operates asynchronously and determines the next state based on the
// current inputs. The second state machine applies the values of the
// asynchronous signals to the synchronous outputs with the system clock.

// Async FSM
always @(*) begin
	case (state)
		idle: begin
			begin
			end
		end
	endcase
end

// Sync FSM
always @(negedge clk or negedge nRESET)
	if (~nRESET) begin
		state	<= idle;
		refack	<= 1'b0;
	end
	else begin
		state	<= nstate;
		// Update synchronous signals
		refack	<= a_refack;
	end

// ---------------------------
//   refresh counter
//   9 bits - 15us interval
// ---------------------------
always @(negedge clk or negedge nRESET) begin
	if (~nRESET)
		q <= 10'b0;
	else begin
		if (refack == 1'b1)
			q <= 10'b0;
		else
			q <= q + 1;
	end
end
// 33MHz input clock = 30.303ns/cycle
// 4096 RAS before CAS refreshes to do per 64ms
// 64ms / 4096 = 15.6us
// 500 cycles * 30.303ns = 15.151us (less than 15.6us)
assign tc = ( q == 9'd500 ) ? 1'b1 : 1'b0;

// Synchronously set refreq to 1 if tc, and to 0 if refack
always @(negedge clk or negedge nRESET) begin
	if (~nRESET)
		refreq <= 1'b0;
	else begin
		if (refack <= 1'b1)
			refreq <= 1'b0;
		else begin
			if (tc == 1'b1)
				refreq <= 1'b1;
		end
	end
end

endmodule
