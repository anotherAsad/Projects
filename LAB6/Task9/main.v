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

module downClocker(pulse, limit, en, clk, reset);
	output reg pulse;
	input  clk, reset, en;
	input [25:0] limit;
	reg   [25:0] out;
	// 24999999 for 1 sec
	always @(posedge clk or negedge reset) begin
		if(~reset) begin
			out <= 26'd0;
			pulse <= 1'b0;
		end
		else if(en) begin
			out <= out + 26'd1;					// Combinational action 1
			if(out == limit) begin				// Combinational action 2
				pulse <= ~pulse;
				out <= 26'd0;
			end
		end
	end
endmodule

module main(HEX3, HEX2, HEX1, HEX0, LEDR, LEDG, SW, KEY, CLOCK_24);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	output [3:0] LEDR, LEDG;
	input  [9:0] SW;
	input  [3:0] KEY;
	input  [0:0] CLOCK_24;
	
	wire   [07:0] A, B, C, D;
	wire   [15:0] rM, M0, M1, R;
	reg    [15:0] bin;
	wire   [03:0] bcd4, bcd3, bcd2, bcd1, bcd0;
	wire   [00:0] gatedClock = CLOCK_24, pulse, cO;			// Not actually Gated
	
	downClocker C0(pulse, 24999999, 1'b1, gatedClock, 1'b1);
//	multiplier #(16) mult0(M0, A, B);
//	multiplier #(16) mult1(M1, C, D);
//	RCAdder    #(16) A0(cO, R, M0, M1, 1'b0);
	
	mac	mac_inst (
	.dataa_0 ( A ),
	.dataa_1 ( C ),
	.datab_0 ( B ),
	.datab_1 ( D ),
	.result ( {cO, R} )
	);


	register #(08) R0(A, SW[7:0], gatedClock, ~KEY[3], 1'b1);
	register #(08) R1(B, SW[7:0], gatedClock, ~KEY[2], 1'b1);
	register #(08) R2(C, SW[7:0], gatedClock, ~KEY[1], 1'b1);
	register #(08) R3(D, SW[7:0], gatedClock, ~KEY[0], 1'b1);
	register #(16) R4(rM, R, gatedClock, (SW[9]&SW[8]), 1'b1);
	
	always @(*) begin
		case(SW[9:8])
			2'b11: bin = rM;
			2'b00: bin = {8'b0, SW[7:0]};
			2'b10: bin = {8'b0, ({8{pulse}} & A) | (~{8{pulse}} & B)};
			2'b01: bin = {8'b0, ({8{pulse}} & C) | (~{8{pulse}} & D)};
		endcase
	end
	
	binToBCD16bit  DEC0(bcd4, bcd3, bcd2, bcd1, bcd0, bin);
	bcdToSevSeg    DEC1(HEX0, bcd0);
	bcdToSevSeg    DEC2(HEX1, bcd1);
	bcdToSevSeg    DEC3(HEX2, bcd2);
	bcdToSevSeg    DEC4(HEX3, bcd3);
	
	assign LEDR = bcd4;
	assign LEDG = {4{cO}};
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
