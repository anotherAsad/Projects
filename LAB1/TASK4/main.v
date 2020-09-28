module main(HEX0, SW);
	output [6:0] HEX0;
	input  [2:0] SW;
	wire   [6:0] charCode;
	wire   [6:0] xS = {7{SW[2]}};
	
	assign charCode[0] = ~SW[0];
	assign charCode[1] = SW[1] ^ SW[0];
	assign charCode[2] = SW[1] ^ SW[0];		// Try assign HEX0[2]=HEX0[1]
	assign charCode[3] = ~SW[1] & ~SW[0];
	assign charCode[4] = 1'b0;
	assign charCode[5] = 1'b0;
	assign charCode[6] = SW[1];
	
	assign HEX0 = (~xS & charCode) | (xS & 7'b1111111);
endmodule
