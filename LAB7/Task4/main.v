module counter(Q, in, clk, reset);
	output reg  [3:0] Q;
	input  wire [1:0] in;
	input  wire [0:0] clk, reset;
	
	reg  [3:0] sum;
	
	always @(*) begin
		case(in)
			2'b00: sum <= Q;
			2'b01: sum <= Q + 4'd1;
			2'b10: sum <= Q + 4'd2;
			2'b11: sum <= Q - 4'd1;
		endcase
	end
	
	always @(posedge clk or negedge reset) begin
		if(~reset)
			Q <= 4'b0000;
		else 
			Q <= (sum == 4'd15)?4'd9: sum%10;
	end
endmodule

module main(HEX3, HEX2, HEX1, HEX0, SW, KEY, CLOCK_50);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [1:0] SW;
	input  [3:3] KEY;
	input  [0:0] CLOCK_50;
	
	wire   [3:0] bcd;
	wire   [0:0] clk;
	
	assign HEX3 = 7'h7F;
	assign HEX2 = 7'h7F;
	assign HEX1 = 7'h7F;
	
	counter C0(bcd, SW, clk, KEY[3]);
	downClocker CLK0(clk, 26'd24999999, 1'b1, CLOCK_50, KEY[3]);
	bcdToSevSeg DEC0(HEX0, bcd);
endmodule
