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

module main(HEX1, HEX0, SW);
	output [6:0] HEX1;
	output [6:0] HEX0;
	input  [7:0] SW;
	
	bcdToSevSeg b0(HEX0, SW[3:0]);
	bcdToSevSeg b1(HEX1, SW[7:4]);
endmodule
