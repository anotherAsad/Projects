module main(HEX3, HEX2, HEX1, HEX0, SW);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [5:0] SW;
	
	reg    [3:0] BCD1, BCD0;
	
	assign HEX3 = 7'b1111111;
	assign HEX2 = 7'b1111111;
	
	always @(*) begin
		if (SW < 10)
			{BCD1, BCD0} = {4'd0, SW[3:0]};
		else if (SW < 20)
			{BCD1, BCD0} = {4'd1, SW[3:0]-4'd10};
		else if (SW < 30)
			{BCD1, BCD0} = {4'd2, SW[3:0]-4'd4};
		else if (SW < 40)
			{BCD1, BCD0} = {4'd3, SW[3:0]-4'd14};
		else if (SW < 50)
			{BCD1, BCD0} = {4'd4, SW[3:0]-4'd8};
		else if (SW < 60)
			{BCD1, BCD0} = {4'd5, SW[3:0]-4'd2};
		else
			{BCD1, BCD0} = {4'd6, SW[3:0]-4'd12};
	end
	
	bcdToSevSeg SSDEC0(HEX0, BCD0);
	bcdToSevSeg SSDEC1(HEX1, BCD1);
endmodule 


module bcdToSevSeg(out, in);
	output reg [6:0] out;
	input  [3:0] in;
	
	always @(*) begin
		case (in)
			4'b0000: out = 7'b1000000;
			4'b0001: out = 7'b1111001;
			4'b0010: out = 7'b0100100;
			4'b0011: out = 7'b0110000;
			4'b0100: out = 7'b0011001;
			4'b0101: out = 7'b0010010;
			4'b0110: out = 7'b0000010;
			4'b0111: out = 7'b1111000;
			4'b1000: out = 7'b0000000;
			4'b1001: out = 7'b0010000;
			default: out = 7'b1111111;
		endcase
	end
endmodule 