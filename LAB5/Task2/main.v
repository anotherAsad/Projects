module rollbackCounter(carry, out, limit, pload, EN, load, clk, reset);
	output carry;
	output reg [3:0] out;
	input  [3:0] limit, pload;
	input  EN, clk, reset, load;
	
	assign carry = EN & (out == limit);
	
	always @(posedge clk or negedge reset or negedge load) begin
		if(~reset)
			out <= 4'b0000;
		else if(~load)
			out <= pload;
		else if(EN)
			if(out == limit)
				out <= 4'b0000;
			else
				out <= out + 4'b0001;
	end
endmodule

module main(HEX3, HEX2, HEX1, HEX0, SW, KEY, CLOCK_50);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [0:0] SW;
	input  [3:0] KEY;
	input  CLOCK_50;
	
	wire   clk, c0, c1, c2, c3, c4, c5;
	wire   [6:0] hex3, hex2, hex1, hex0;
	reg    [3:0] bcd0, bcd1, bcd2, bcd3;
	wire   [3:0] H1, H0, M1, M0, S1, S0;
	
	downClocker CK(clk, CLOCK_50, KEY[3], SW);
	
	rollbackCounter  C0(c0, S0, 4'd9, 4'd5, SW, KEY[2], clk, KEY[3]);
	rollbackCounter  C1(c1, S1, 4'd5, 4'd5, c0, KEY[2], clk, KEY[3]);
	rollbackCounter  C2(c2, M0, 4'd9, 4'd5, c1, KEY[2], clk, KEY[3]);
	rollbackCounter  C3(c3, M1, 4'd5, 4'd5, c2, KEY[2], clk, KEY[3]);
	rollbackCounter  C4(c4, H0, 4'd3, 4'd5, c3, KEY[2], clk, KEY[3]);
	rollbackCounter  C5(c5, H1, 4'd2, 4'd5, c4, KEY[2], clk, KEY[3]);
	
	always @(*) begin
		if(KEY[1] & KEY[0])
			{bcd3, bcd2, bcd1, bcd0} = {4'd2, 4'd8, S1, S0};
		else if(~KEY[1] & KEY[0])
			{bcd3, bcd2, bcd1, bcd0} = {4'd1, 4'd8, M1, M0};
		else
			{bcd3, bcd2, bcd1, bcd0} = {4'd7, 4'd8, H1, H0};
	end
	
	assign HEX3 = ~hex3;
	assign HEX2 = ~hex2;
	assign HEX1 =  hex1;
	assign HEX0 =  hex0;
	
	bcdToSevSeg DEC0(hex0, bcd0);
	bcdToSevSeg DEC1(hex1, bcd1);
	bcdToSevSeg DEC2(hex2, bcd2);
	bcdToSevSeg DEC3(hex3, bcd3);
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
