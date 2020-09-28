// Fmax = 76.12 MHz
// Total LE's = 1281 (7%)

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

module multiplier(M, A, B);
	parameter WIDTH = 8;
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

module main0(out, in1, in2);
	parameter WIDTH = 8;
	output [2*WIDTH-1:0] out;
	input  [WIDTH-1:0] in1, in2;
	multiplier #(WIDTH) M0(out, in1, in2);
endmodule

module main(HEX3, HEX2, HEX1, HEX0, LEDR, SW, KEY, CLOCK_24);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	output [3:0] LEDR;
	input  [9:0] SW;
	input  [3:1] KEY;
	input  [0:0] CLOCK_24;
	
	wire   [07:0] A, B;
	wire   [15:0] rM, M;
	reg    [15:0] bin;
	wire   [03:0] bcd4, bcd3, bcd2, bcd1, bcd0;
	wire   [00:0] gatedClock = CLOCK_24;			// Not actually Gated
	multiplier M0(M, A, B);
	
	register #(08) R0(A, SW[7:0], gatedClock, ~KEY[2], KEY[3]);
	register #(08) R1(B, SW[7:0], gatedClock, ~KEY[1], KEY[3]);
	register #(16) R2(rM, M, gatedClock, (SW[9]&SW[8]), KEY[3]);
	
	always @(*) begin
		case(SW[9:8])
			2'b11: bin = rM;
			2'b00: bin = {8'b0, SW[7:0]};
			2'b10: bin = {8'b0, A};
			2'b01: bin = {8'b0, B};
		endcase
	end
	
	binToBCD16bit  DEC0(bcd4, bcd3, bcd2, bcd1, bcd0, bin);
	bcdToSevSeg    DEC1(HEX0, bcd0);
	bcdToSevSeg    DEC2(HEX1, bcd1);
	bcdToSevSeg    DEC3(HEX2, bcd2);
	bcdToSevSeg    DEC4(HEX3, bcd3);
	
	assign LEDR = bcd4;
endmodule

module binToBCD16bit(bcd4, bcd3, bcd2, bcd1, bcd0, S);
	output [03:0] bcd4, bcd3, bcd2, bcd1, bcd0;
	input  [15:0] S;
	
	assign bcd0 = (S%16'd00010);
	assign bcd1 = (S/16'd00010)%16'd10;
	assign bcd2 = (S/16'd00100)%16'd10;
	assign bcd3 = (S/16'd01000)%16'd10;
	assign bcd4 = (S/16'd10000);
endmodule
