// The exercise expects us to make a 3 bit wide 5x3 mux.
// For the lack of sufficient switches. We will make a 2 bit wide 5x3 mux
// by chaining 2 bit wide 2x1 muxes

// The exercise instructs on chaining 2x1 muxes to make bigger muxes
module twoMux2(out, in1, in0, s);
	output [1:0] out;			// As can be seen, the width is 2 bits.
	input  [1:0] in0, in1;
	input  s;
	wire   [1:0] xS = {2{s}};
	
	assign out = (~xS & in0) | (xS & in1);
endmodule

module twoMux5(out, in4, in3, in2, in1, in0, s);
	output [1:0] out;
	input  [1:0] in4, in3, in2, in1, in0;
	input  [2:0] s;
	
	wire   [1:0] w2, w1, w0;
	
	twoMux2 m0(w0, in1, in0, s[0]);
	twoMux2 m1(w1, in3, in2, s[0]);
	twoMux2 m2(w2, w1, w0, s[1]);
	twoMux2 m3(out, in4, w2, s[2]);
endmodule

module code(LEDG, LEDR, SW, KEY);
	output [1:0] LEDG;
	output [9:0] LEDR;
	input  [9:0] SW;
	input  [3:1] KEY;
	
	assign LEDR = SW;
	twoMux5 MUX0(LEDG, SW[9:8], SW[7:6], SW[5:4], SW[3:2], SW[1:0], ~KEY);
endmodule 

// As an exercise, one may implement the twoMux5 with assign statements only.
