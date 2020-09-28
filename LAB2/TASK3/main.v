module fullAdder(s, cO, A, B, cI);
	output s, cO;
	input  A, B, cI;
	
	wire w0;
	assign w0 = A ^ B;
	assign s  = w0 ^ cI;
	assign cO = (~w0 & B) | (w0 & cI);
endmodule 

module rippleCarry(out, cOut, in1, in0, cIn);
	output [3:0] out;
	output cOut;
	input  [3:0] in1, in0;
	input  cIn;
	
	wire   [2:0] w;
	
	fullAdder FA0(out[0], w[0], in1[0], in0[0], cIn);
	fullAdder FA1(out[1], w[1], in1[1], in0[1], w[0]);
	fullAdder FA2(out[2], w[2], in1[2], in0[2], w[1]);
	fullAdder FA3(out[3], cOut, in1[3], in0[3], w[2]);
endmodule

module main(HEX1, HEX0, LEDG, LEDR, SW);
	output [4:0] LEDG;
	output [9:0] LEDR;
	output [6:0] HEX1, HEX0;
	input  [9:0] SW;
	
	assign LEDR = SW;
	rippleCarry RC0(LEDG[3:0], LEDG[4], SW[9:6], SW[3:0], SW[5]);
	sevSegInterface SSI(HEX1, HEX0, LEDG[3:0]);		// This is an additional line. HEX1, 2 also
endmodule

//  BCD to sevSeg using sevSegInterface. The for displaying 7 seg. This is additional.
module sevSegInterface(hex1, hex0, inp);
	output [6:0] hex1, hex0;
	input  [3:0] inp;
	
	wire   [3:0] muxOut;
	wire   [2:0] cktAOut;
	wire   compOut;
	
	bcdComparator BCOMP0(compOut, inp[3:0]);
	cktA CKA0(cktAOut, inp[2:0]);
	cktB CKB0(hex1, compOut);
	fourMux2 MUX0(muxOut, {1'b0 ,cktAOut}, inp[3:0], compOut);
	bcdToSevSeg BCD0(hex0, muxOut);
endmodule 

module bcdToSevSeg(out, in);
	output [6:0] out;
	input  [3:0] in;
	
	wire A = in[3], B = in[2], C =in[1], D = in[0];
	
	assign out[0] = (~A&~C)&(B^D);
	assign out[1] = (~A&B)&(C^D);
	assign out[2] = (~A&~B&C&~D);
	assign out[3] = (~A&B&~(C^D))|(~A&~B&~C&D);
	assign out[4] = (A&D) | (~A&~B&D) | (~A&B&(~C|D));
	assign out[5] = (~A&~B)&(C|D);
	assign out[6] = (~A&~B&~C)|(~A&B&C&D);
endmodule

module bcdComparator(out, in);
	output out;
	input  [3:0] in;
	wire   [4:0] diff;
	
	assign diff = 5'b01001-{1'b0, in};
	assign out =  diff[4];
endmodule

module cktA(out, in);
	output [2:0] out;
	input  [2:0] in;
	
	assign out = {(in[2]&~in[1])^in[2] , ~in[1], in[0]};
endmodule

module cktB(out, in);
	output [6:0] out;
	input  in;
	
	// 'in' is the output of comparator. 1 means 1, 0 means 0.
	assign out = {1'b1, in, in, in, 1'b0, 1'b0, in};
endmodule

module fourMux2(out, in1, in0, s);
	output [3:0] out;
	input  [3:0] in1, in0;
	input  s;
	
	wire   [3:0] xS = {4{s}};
	assign out = (~xS&in0) | (xS&in1);
endmodule

module tb;

endmodule 
