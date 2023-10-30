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
wire		reftimer;	// Refresh counter equals limit
reg [8:0]	refc;		// Refresh counter
reg		refack;		// Refresh Acknowledge

reg [12:0]	initc;		// Initialization counter
wire		inittimer;	// Init counter equals limit
reg		initdone;	// Initialization is done (stays 1 after inittimer goes high)

reg [3:0]	state, nstate;	// Current state, next state

// states
parameter [3:0] init0	= 4'b0000;	// Wait for 200us init delay
parameter [3:0]	init1	= 4'b0001;	// Wait for 8 refresh cycles
parameter [3:0] dummy0	= 4'b0010;
parameter [3:0] dummy1	= 4'b0011;
parameter [3:0] dummy2	= 4'b0100;
parameter [3:0] dummy3	= 4'b0101;
parameter [3:0] dummy4	= 4'b0110;
parameter [3:0] dummy5	= 4'b0111;
parameter [3:0] dummy6	= 4'b1000;
parameter [3:0] dummy7	= 4'b1001;
parameter [3:0] dummy8	= 4'b1010;
parameter [3:0] dummy9	= 4'b1011;
parameter [3:0] dummyA	= 4'b1100;
parameter [3:0] dummyB	= 4'b1101;
parameter [3:0] dummyC	= 4'b1110;
parameter [3:0] dummyD	= 4'b1111;

// The DRAM controller is implemented as two finite-state machines. The first
// machine operates asynchronously and determines the next state based on the
// current inputs. The second state machine applies the values of the
// asynchronous signals to the synchronous outputs with the system clock.

// Async FSM
always @(*) begin
	case (state)
		init0: begin			// Wait for 200us init delay
			if (initdone == 1'b1) begin
				nstate	<= init1;
				// Set other outputs to init state
			end
		end

		init1: begin
			if (initrefdone == 1'b1) begin
				nstate	<= idle;
	endcase
end

// Sync FSM
always @(negedge clk or negedge nRESET)
	if (~nRESET) begin
		state	<= init0;
		refack	<= 1'b0;
	end
	else begin
		state	<= nstate;
		// Update synchronous signals
		refack	<= a_refack;
	end

// ---------------------------
//   initialization timer
//   13 bits - 200us interval
// ---------------------------
always @(negedge clk or negedge nRESET) begin
	if (~nRESET)
		initc	<= 13'b0;
	else begin
		initc	<= initc + 1;
	end
end
// 33MHz input clock = 30.303ns/cycle
// DRAM Datasheet wants 200us after powerup for initialization
// 200us / 30.303ns = 6600
assign inittimer = ( initc == 13'd6600 ) ? 1'b1 : 1'b0;

always @(negedge clk or negedge nRESET) begin
	if (~nRESET)
		initdone <= 1'b0;
	else begin
		if (inittimer == 1'b1)
			initdone <= 1'b1;
	end
end

// ---------------------------
//   refresh counter
//   9 bits - 15us interval
// ---------------------------
always @(negedge clk or negedge nRESET) begin
	if (~nRESET)
		refc <= 10'b0;
	else begin
		if (refack == 1'b1)
			refc <= 10'b0;
		else
			refc <= refc + 1;
	end
end
// 33MHz input clock = 30.303ns/cycle
// 4096 RAS before CAS refreshes to do per 64ms
// 64ms / 4096 = 15.6us
// 500 cycles * 30.303ns = 15.151us (less than 15.6us)
assign reftimer = ( refc == 9'd500 ) ? 1'b1 : 1'b0;

// Synchronously set refreq to 1 if reftimer, and to 0 if refack
always @(negedge clk or negedge nRESET) begin
	if (~nRESET)
		refreq <= 1'b0;
	else begin
		if (refack <= 1'b1)
			refreq <= 1'b0;
		else begin
			if (reftimer == 1'b1)
				refreq <= 1'b1;
		end
	end
end

endmodule
