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

module main(HEX1, HEX0, SW);
	output [6:0] HEX1, HEX0;
	input  [3:0] SW;
	
	wire   [3:0] muxOut;
	wire   [2:0] cktAOut;
	wire   compOut;
	
	bcdComparator BCOMP0(compOut, SW[3:0]);
	cktA CKA0(cktAOut, SW[2:0]);
	cktB CKB0(HEX1, compOut);
	fourMux2 MUX0(muxOut, {1'b0 ,cktAOut}, SW[3:0], compOut);
	bcdToSevSeg BCD0(HEX0, muxOut);
endmodule 