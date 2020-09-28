module fullAdder(s1, s0, A, B, C);
	output s1, s0;
	input  A, B, C;
	
	wire midSum = A ^ B;
	assign s0 = midSum ^ C;
	wire midCry2 = midSum & C;
	wire midCry1 = A & B;
	assign s1 = midCry1 | midCry2;
endmodule

module RC_AddSub(cO, ov, out, A, B, opSel);
	output ov, cO;
	output [7:0] out;
	input  opSel;
	input  [7:0] A, B;
	wire   [8:0] C;		// Intermediate carry line
	wire   [7:0] signedB;
	
	assign {C[0], cO} = {opSel, C[8]};
	assign ov = C[8] ^ C[7];
	
	xor xorline[7:0](signedB, B, {8{C[0]}});

	generate
		genvar i;
		for(i=0; i<8; i=i+1) begin: m
			fullAdder FA(C[i+1], out[i], A[i], signedB[i], C[i]);
		end
	endgenerate
endmodule

module register(out, in, clk, en, reset);
	parameter WIDTH = 8;
	
	output reg [WIDTH-1:0] out;
	input  [WIDTH-1:0] in;
	input  reset, en, clk;
	
	always @(posedge clk or negedge reset) begin
		if(~reset)
			out <= {WIDTH{1'b0}};
		else if(en)
			out <= in;
	end
endmodule

module regAddSub(Cout, overflow, S, rA, rB, A, B, wrA, wrB, opSel, clk, reset);
	output Cout, overflow;
	output [7:0] S, rA, rB;
	input  [7:0] A, B;
	input  wrA, wrB, clk, opSel, reset;
	
	wire   [7:0] out;
	wire   ov;
	RC_AddSub RCA(Cout, ov, out, rA, rB, opSel);
	
	register #(8) I0(rA,  A, clk, wrA, reset);
	register #(8) I1(rB,  B, clk, wrB, reset);
	register #(8) O0(S, out, clk, 1'b1, reset);
	register #(1) OV(overflow, ov, clk, 1'b1, reset);
endmodule

// This is some gourmet adder/subtractor as well. Works in A+B mode with 8bit range
// Works is A-B mode with 7bit range. The cue for A-B is SW[9]&SW[8]. Not only does
// the cue convert the B to -B and pass HI carry-in for subtraction, it also switches
// To signed display mode on 7seg Display. The output, if in range will be shown with
// proper sign. + for S < 128, - for S > 128.
module main(HEX3, HEX2, HEX1, HEX0, LEDR, SW, KEY, CLOCK_24);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	output [1:0] LEDR;
	input  [3:1] KEY;
	input  [9:0] SW;
	input  [0:0] CLOCK_24;
	
	wire   [7:0] S, invS, bin, rA, rB, sel1, sel0;
	wire   [3:0] bcd2, bcd1, bcd0;
	
	regAddSub      RSA(LEDR[1], LEDR[0], S, rA, rB, SW[7:0], SW[7:0], ~KEY[2], ~KEY[1], SW[9] & SW[8], CLOCK_24, KEY[3]);
	
	binToBCD8bit   DEC0(bcd2, bcd1, bcd0, bin);
	bcdToSevSeg    DEC1(HEX0, bcd0);
	bcdToSevSeg    DEC2(HEX1, bcd1);
	bcdToSevSeg    DEC3(HEX2, bcd2);
	
	assign {_, invS} = (S > 8'd127) ? (9'd256 - {1'b0, S}) : {1'b0, S};
	assign HEX3 = {~(SW[9]&SW[8]&S[7]), 6'h3F};
	assign {sel1, sel0} = {  {8{SW[9]}} , {8{SW[8]}}  };
	assign bin = (~sel1 & ~sel0 & S) | (sel1 & sel0 & invS) | (sel1 & ~sel0 & rA) | (~sel1 & sel0 & rB);
endmodule

module binToBCD8bit(bcd2, bcd1, bcd0, S);
	output [3:0] bcd2, bcd1, bcd0;
	input  [7:0] S;

	wire   [3:0] notUsed [0:2];
	
	assign {notUsed[0], bcd0} = (S % 8'd10);
	assign {notUsed[1], bcd1} = (S/8'd10)%8'd10;
	assign {notUsed[2], bcd2} = (S/8'd100);
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
