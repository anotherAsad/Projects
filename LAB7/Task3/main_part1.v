module shiftReg(Q, D, clk, reset, preset);
	output reg [3:0] Q;
	input  D, clk, reset, preset;
	
	always @(posedge clk or negedge reset or negedge preset) begin
		if(~reset)
			Q <= 4'b0000;
		else if(~preset)
			Q <= 4'b1111;
		else
			Q[3:0] = {Q[2:0], D};
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
	
	assign zero = {7{~(|LEDR[3:0])}};
	assign one  = {7{ (&LEDG[3:0])}};
	
	assign HEX3 = 7'h7F;
	assign HEX2 = 7'h7F;
	assign HEX1 = 7'h7F;
	assign HEX0 = (~zero | 7'b1000000) & (~one | 7'b1111001);
	
	downClocker C0(clk, 26'd24999999, 1'b1, CLOCK_50, KEY[3]);
	// FSM
	shiftReg SR1(LEDG[3:0], ~KEY[2], clk, KEY[3], 1'b1);
	shiftReg SR0(LEDR[3:0], ~KEY[2], clk, 1'b1, KEY[3]);
endmodule

