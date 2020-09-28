// FSM with one 4-bit shift register. Approximately correct.
module shiftRegSeqDetector(Q, D, clk, reset);
	output reg [3:0] Q;
	input  D, clk, reset;
	
	always @(posedge clk or negedge reset) begin
		if(~reset)
			Q <= {D, ~D, D, ~D};
		else
			Q <= {Q[2:0], D};
	end
endmodule

module main(HEX3, HEX2, HEX1, HEX0, LEDR, LEDG, KEY, CLOCK_50);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	output [3:0] LEDR, LEDG;
	input  [3:2] KEY;
	input  [0:0] CLOCK_50;
	
	wire   [0:0] clk;
	wire   [6:0] zero, one;
	wire   [3:0] bin;
	
	assign zero = {7{~(|LEDR)}};
	assign one  = {7{ (&LEDR)}};
	
	assign LEDG = zero[3:0] | one[3:0];
	assign HEX3 = 7'h7F;
	assign HEX2 = 7'h7F;
	assign HEX1 = 7'h7F;
	assign HEX0 = (~zero | 7'b1000000) & (~one | 7'b1111001);	// Active low mux
	
	downClocker C0(clk, 26'd24999999, 1'b1, CLOCK_50, KEY[3]);
	shiftRegSeqDetector FSM(LEDR, ~KEY[2], clk, KEY[3]);
endmodule
