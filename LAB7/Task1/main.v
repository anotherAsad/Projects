// Write a verilog code that instantiates 9 FlipFlops in a circuit
module ff(out, in, clk, reset);
	output reg out;
	input  in, clk, reset;
	
	always @(posedge clk or negedge reset) begin
		if(~reset)
			out <= 1'b0;
		else
			out <= in;
	end
endmodule

// Personal variation of second task. Uses one less FF.
module fsm(z, state, w, reset, clk);	// Reset is active low
	output z;
	output [7:0] state;
	input  w, reset, clk;
	
	wire   in0, in1;
	wire   [7:0] commClk = {8{clk}};
	wire   [7:0] driver;

	assign {in0, in1}= {~w, w};
	
	assign driver[7] = in0 & ~(|state[7:4]);
	assign driver[6] = in0 & state[7];
	assign driver[5] = in0 & state[6];
	assign driver[4] = in0 & (state[5] | state[4]);
	assign driver[3] = in1 & ~(|state[3:0]);
	assign driver[2] = in1 & state[3];
	assign driver[1] = in1 & state[2];
	assign driver[0] = in1 & (state[1] | state[0]);
	
	assign z = state[4] | state[0];
	
	ff stateFF[7:0](state, driver, commClk, {8{reset}});
endmodule

module main(LEDR, LEDG, KEY, CLOCK_50);
	output [0:8] LEDR;
	output [0:0] LEDG;
	input  [3:2] KEY;
	input  [0:0] CLOCK_50;
	
	wire   [0:0] clk;
	
	downClocker DC0(clk, 26'd24999999, 1'b1, CLOCK_50, KEY[3]);
	fsm  FSM0(LEDG, LEDR[1:8], ~KEY[2], KEY[3], clk);
	assign LEDR[0] = ~KEY[3];
endmodule
