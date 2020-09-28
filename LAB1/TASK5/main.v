// This exercise is heavily modified due to lack of sufficient switches and 
// Hex Displays

module twoMux5(out, in4, in3, in2, in1, in0, s);
	output [1:0] out;
	input  [1:0] in4, in3, in2, in1, in0;
	input  [2:0] s;
	
	wire   [1:0] w2, w1, w0;
	wire   [1:0] xS0 = {2{s[0]}};
	wire   [1:0] xS1 = {2{s[1]}};
	wire   [1:0] xS2 = {2{s[2]}};
	
	assign w0 = (~xS0&in0) | (xS0&in1);
	assign w1 = (~xS0&in2) | (xS0&in3);
	assign w2 = (~xS1&w0)  | (xS1&w1);
	assign out = (~xS2&w2) | (xS2&in4);
endmodule

module decoder(DISP, C);
	output [6:0] DISP;
	input  [2:0] C;
	wire   [6:0] charCode;
	wire   [6:0] xS = {7{C[2]}};
	
	assign charCode[0] = ~C[0];
	assign charCode[1] = C[1] ^ C[0];
	assign charCode[2] = C[1] ^ C[0];		// Try assign DISP[2]=DISP[1]
	assign charCode[3] = ~C[1] & ~C[0];
	assign charCode[4] = 1'b0;
	assign charCode[5] = 1'b0;
	assign charCode[6] = C[1];
	
	assign DISP = (~xS & charCode) | (xS & 7'b1111111);
endmodule

module main(HEX3, HEX2, HEX1, HEX0, LEDR, LEDG, SW, KEY);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	output [9:0] LEDR;
	output [1:0] LEDG;
	input  [9:0] SW;
	input  [2:1] KEY;
	
	wire   [1:0] muxOut0, muxOut1, muxOut2, muxOut3; 
	wire   [6:0] decOut0, decOut1, decOut2, decOut3;
	
	assign LEDR = SW;
	assign LEDG = muxOut0;
	
	assign HEX3 = decOut0;
	assign HEX2 = decOut1;
	assign HEX1 = decOut2;
	assign HEX0 = decOut3;
	
	assign muxOut1 = muxOut0+2'b01;
	assign muxOut2 = muxOut1+2'b01;
	assign muxOut3 = muxOut2+2'b01;
	
	twoMux5 MUX0(muxOut0, 2'b0, SW[7:6], SW[5:4], SW[3:2], SW[1:0], {1'b0, ~KEY[2:1]});
	decoder DEC0(decOut0, {SW[9], muxOut0});
	decoder DEC1(decOut1, {SW[9], muxOut1});
	decoder DEC2(decOut2, {SW[9], muxOut2});
	decoder DEC3(decOut3, {SW[9], muxOut3});
endmodule 