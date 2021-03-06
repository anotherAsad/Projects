module main(HEX3, HEX2, HEX1, HEX0, SW);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [9:0] SW;
	
	wire   [4:0] binOut0, binOut1;
	wire   [3:0] BCD3, BCD2, BCD1, BCD0;
	
	assign HEX3 = 7'b1111111;
	rippleCarry RCA0(binOut0, SW[3:0], SW[3:0], SW[5]);
	binToBCD    CN0(BCD1, BCD0,binOut0);
	rippleCarry RCA1(binOut1, SW[9:6], SW[9:6], BCD1[0]);
	binToBCD    CN1(BCD3, BCD2,binOut1);
	
	bcdToSevSeg BCDtoSevSeg0(HEX0, BCD0);
	bcdToSevSeg BCDtoSevSeg1(HEX1, BCD2);
	bcdToSevSeg BCDtoSevSeg2(HEX2, BCD3);
endmodule 

module testbench;
	reg  [9:0] SW;
	wire [6:0] HEX0, HEX1, HEX2, HEX3;
	
	integer i, j;
	
	main myMain(HEX3, HEX2, HEX1, HEX0, SW);
	
	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0, testbench);
		#0 SW = {4'd00, 2'd0, 4'd0};
		
		for (i=0; i <=9; i=i+1) begin
			for(j=0; j<=9; j=j+1) begin
				#1 SW = {i[3:0], 2'd0, j[3:0]};
			end
		end
	end
endmodule

module binToBCD(bcd1, bcd0, in);
	output [3:0] bcd1, bcd0;
	input  [4:0] in;
	
	wire   [3:0] digS = {4{in[4] | (in[3] & (in[2]|in[1]))}};// Digit Select (Below or above 9)
	wire   [3:0] abv9 = {in[4]&in[1], ~(in[2]^in[1]), ~in[1], in[0]};
	
	assign bcd0 = (~digS & in[3:0]) | (digS & abv9);
	assign bcd1 = (~digS & 4'b0000) | (digS & 4'b0001);
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

// Adder Down Below
module fullAdder(s, cO, A, B, cI);
	output s, cO;
	input  A, B, cI;
	
	wire w0;
	assign w0 = A ^ B;
	assign s  = w0 ^ cI;
	assign cO = (~w0 & B) | (w0 & cI);
endmodule 

module rippleCarry(out, in1, in0, cIn);
	output [4:0] out;
	input  [3:0] in1, in0;
	input  cIn;
	
	wire   [2:0] wci;
	
	fullAdder FA0(out[0], wci[0], in1[0], in0[0], cIn);
	fullAdder FA1(out[1], wci[1], in1[1], in0[1], wci[0]);
	fullAdder FA2(out[2], wci[2], in1[2], in0[2], wci[1]);
	fullAdder FA3(out[3], out[4], in1[3], in0[3], wci[2]);
endmodule 