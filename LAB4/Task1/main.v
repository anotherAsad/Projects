// Uses 50 LEs on DE1. Including Peripherals
// Slow Model Fmax = 293.08MHz

module main(HEX3, HEX2, HEX1, HEX0, KEY, SW);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [3:2] KEY;
	input  [0:0] SW;
	
	wire   [3:0] nibble [4];
	hexToSevSeg DEC0(HEX0, nibble[0]);
	hexToSevSeg DEC1(HEX1, nibble[1]);
	hexToSevSeg DEC2(HEX2, nibble[2]);
	hexToSevSeg DEC3(HEX3, nibble[3]);
	
	syncCounter #(64)SC0({nibble[3], nibble[2], nibble[1], nibble[0]}, SW, ~KEY[3], KEY[2]);
endmodule 

module #(parameter WIDTH = 16) syncCounter(out, EN, CLK, clear);
	output [WIDTH-1:0] out;
	input  EN, CLK, clear;
	
	wire	[WIDTH-1:0] Q, T;
	
	assign	T[0] = EN;
	assign  out = Q;
	tFFR	TF0(Q[0], T[0], CLK, clear);
	
	generate
		genvar i;
		for(i = 1; i < WIDTH; i=i+1) begin : m
			and  AG(T[i], Q[i-1], T[i-1]);
			tFFR TF(Q[i], T[i], CLK, clear);
		end
	endgenerate
endmodule

module tFFR(Q, T, CLK, reset);
	output reg Q;
	input  T, CLK, reset;
	
	always @(posedge CLK or negedge reset) begin
		if(~reset)
			Q <= 1'b0;
		else if(T == 1'b1)
			Q <= ~Q;
	end
endmodule

module hexToSevSeg(out, in);
	output reg [6:0] out;
	input  [3:0] in;
	
	always @(*) begin
		case(in)
			4'h0: out = 7'b1000000;
			4'h1: out = 7'b1111001;
			4'h2: out = 7'b0100100;
			4'h3: out = 7'b0110000;
			4'h4: out = 7'b0011001;
			4'h5: out = 7'b0010010;
			4'h6: out = 7'b0000010;
			4'h7: out = 7'b1111000;
			4'h8: out = 7'b0000000;
			4'h9: out = 7'b0010000;
			4'hA: out = 7'b0001000;
			4'hB: out = 7'b0000011;
			4'hC: out = 7'b1000110;
			4'hD: out = 7'b0100001;
			4'hE: out = 7'b0000110;
			4'hF: out = 7'b0001110;
		endcase
	end
endmodule 