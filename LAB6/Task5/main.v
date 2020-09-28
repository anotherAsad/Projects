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


module fullAdder(s1, s0, A, B, C);
	output s1, s0;
	input  A, B, C;
	
	wire midSum = A ^ B;
	assign s0 = midSum ^ C;
	wire midCry2 = midSum & C;
	wire midCry1 = A & B;
	assign s1 = midCry1 | midCry2;
endmodule

module RCAdder(cO, out, A, B, cI);
	parameter WIDTH = 8;
	output cO;
	output [WIDTH-1:0] out;
	input  cI;
	input  [WIDTH-1:0] A, B;
	wire   [WIDTH:0] C;		// Intermediate carry line
	
	assign {C[0], cO} = {cI, C[WIDTH]};
		
	generate
		genvar i;
		for(i=0; i<WIDTH; i=i+1) begin: m
			fullAdder FA(C[i+1], out[i], A[i], B[i], C[i]);
		end
	endgenerate
endmodule

module multiplier(M, A, B);
	parameter WIDTH = 4;
	output [2*WIDTH-1:0] M;
	input  [WIDTH-1:0] A, B;

	wire   [WIDTH-1:0] andLine [WIDTH-1:0];
	wire   [WIDTH-1:0] sumLine [WIDTH-1:0];
	wire   [WIDTH-1:0] cO;
	
	assign sumLine[0] = andLine[0];
	assign cO[0] = 1'b0;
	
	generate
		genvar i;
		for(i=0; i<WIDTH; i=i+1) begin: m
			assign andLine[i] = A & {WIDTH{B[i]}};
			assign M[i] = sumLine[i][0];
		end
	endgenerate
	
	generate
		for(i=0; i<WIDTH-1; i=i+1) begin: n
			RCAdder #(WIDTH) RCA(cO[i+1], sumLine[i+1], {cO[i],sumLine[i][WIDTH-1:1]}, andLine[i+1], 1'b0);
		end
	endgenerate
	
	assign M[2*WIDTH-1: WIDTH] = {cO[WIDTH-1], sumLine[WIDTH-1][WIDTH-1:1]};
endmodule

module main(HEX3, HEX2, HEX1, HEX0, SW);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [9:0] SW;
	
	wire   [7:0] bin;
	wire   [3:0] bcd2, bcd1, bcd0;
	
	multiplier M0(bin, SW[3:0], SW[7:4]);
	
	binToBCD8bit   DEC0(bcd2, bcd1, bcd0, bin);
	bcdToSevSeg    DEC1(HEX0, bcd0);
	bcdToSevSeg    DEC2(HEX1, bcd1);
	bcdToSevSeg    DEC3(HEX2, bcd2);
	
	assign HEX3 = 7'h7F;
endmodule

module binToBCD8bit(bcd2, bcd1, bcd0, S);
	output [3:0] bcd2, bcd1, bcd0;
	input  [7:0] S;

	wire   [3:0] notUsed [0:2];
	
	assign {notUsed[0], bcd0} = (S % 8'd10);
	assign {notUsed[1], bcd1} = (S/8'd10)%8'd10;
	assign {notUsed[2], bcd2} = (S/8'd100);
endmodule
 