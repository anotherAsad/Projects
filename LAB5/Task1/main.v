module main(HEX3, HEX2, HEX1, HEX0, SW, KEY, CLOCK_50);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [0:0] SW;
	input  [3:3] KEY;
	input  CLOCK_50;
	
	wire   clk, c0, c1, c2, c3;
	wire   [3:0] bcd0, bcd1, bcd2, bcd3;
	
	downClocker CK(clk, CLOCK_50, KEY, SW);
	
	bcdCounter  C0(c0, bcd0, SW, clk, KEY);
	bcdCounter  C1(c1, bcd1, c0, clk, KEY);
	bcdCounter  C2(c2, bcd2, c1, clk, KEY);
	bcdCounter  C3(c3, bcd3, c2, clk, KEY);
	
	bcdToSevSeg DEC0(HEX0, bcd0);
	bcdToSevSeg DEC1(HEX1, bcd1);
	bcdToSevSeg DEC2(HEX2, bcd2);
	bcdToSevSeg DEC3(HEX3, bcd3);
endmodule

module bcdCounter(carry, out, EN, clk, reset);
	output carry;
	output reg [3:0] out;
	input  EN, clk, reset;
	
	assign carry = EN & (out[3] & ~out[2] & ~out[1] & out[0]);
	
	always @(posedge clk or negedge reset) begin
		if(~reset)
			out <= 4'b0000;
		else if(EN)
			if(out == 4'b1001)
				out <= 4'b0000;
			else
				out <= out + 4'b0001;
	end
endmodule 

module downClocker(pulse, clk, reset, en);
	output reg pulse;
	input  clk, reset, en;
	reg [25:0] out;
	// 24999999 for 1 sec
	always @(posedge clk or negedge reset) begin
		if(~reset) begin
			out <= 26'd0;
			pulse <= 1'b0;
		end
		else if(en) begin
			out <= out + 26'd1;				// Combinational action 1
			if(out == 26'd4999999) begin	// Combinational action 2
				pulse <= ~pulse;
				out <= 26'd0;
			end
		end
	end
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
