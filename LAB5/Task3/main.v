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

module dflipflop(Q, D, clk, reset);
	output reg Q;
	input  D, reset, clk;
	
	always @(posedge clk or negedge reset)
		if(~reset)
			Q <= 0;
		else
			Q <= D;
endmodule

module main(HEX3, HEX2, HEX1, HEX0, LEDR, SW, KEY, CLOCK_50);
	output [6:0] HEX3, HEX2, HEX1, HEX0, LEDR;
	input  [3:2] KEY;
	input  [4:0] SW;
	input  [0:0] CLOCK_50;
	
	wire pulse, clk, secClockIn, milClockIn, c0, c1, c2, c3, c4, msSig, eHalt;
	wire [3:0] out0, out1, out2, out3, out4;
	
	// Clock gating at clock dividers for max power conservation (O really?)
	assign secClockIn = CLOCK_50 & ~msSig;
	assign milClockIn = CLOCK_50 & ~eHalt;
	assign LEDR = {7{msSig}};
	
	downClocker SEC(pulse, 26'd24999999, SW[0], secClockIn, KEY[3]);
	downClocker MSC(clk  , 26'd00024999, SW[0], milClockIn, KEY[3]);
	
	// Counts the seconds and then generates a carry signal that cues next action.
	rollbackCounter C0(c0, out0, SW[4:1], 4'd0, 1'b1, 1'b1, pulse, KEY[3]);
	
	// First DFF gates the 'seconds' clock. Second DFF disables 'milliseconds'
	// clock (if the seconds clock has already been disabled and not otherwise).
	// dflipflop DFF0(msSig, c0, pulse, KEY[3]);
	dflipflop DFF0(msSig, 1'b1, c0, KEY[3]);	// Unsafe, undebounced, Will always work.
	dflipflop DFF1(eHalt, 1'b1, ~KEY[2] & msSig, KEY[3]);
	
	// Millisecond Counter Chain
	rollbackCounter C1(c1, out1, 4'd9, 4'd0, msSig, 1'b1, clk, KEY[3]);
	rollbackCounter C2(c2, out2, 4'd9, 4'd0, c1   , 1'b1, clk, KEY[3]);
	rollbackCounter C3(c3, out3, 4'd9, 4'd0, c2   , 1'b1, clk, KEY[3]);
	rollbackCounter C4(c4, out4, 4'd9, 4'd0, c3   , 1'b1, clk, KEY[3]);
	// module rollbackCounter(carry, out, limit, pload, EN, load, clk, reset);

	bcdToSevSeg DEC0(HEX0, out1);
	bcdToSevSeg DEC1(HEX1, out2);
	bcdToSevSeg DEC2(HEX2, out3);
	bcdToSevSeg DEC3(HEX3, out4);
endmodule 