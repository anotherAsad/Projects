// Two Digit BCD adder
module main(HEX3, HEX2, HEX1, HEX0, SW);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [9:0] SW;
	
	reg [5:0] addrOut1, addrOut0;
	reg [3:0] BCD3, BCD2, BCD1, BCD0;
	
	assign HEX3 = 7'b1111111;
	
	bcdToSevSeg SSDEC0(HEX0, BCD0);
	bcdToSevSeg SSDEC1(HEX1, BCD2);
	bcdToSevSeg SSDEC2(HEX2, BCD3);
	
	always @(*) begin
		addrOut0 = SW[3:0]+SW[3:0]+SW[5];
		addrOut1 = SW[9:6]+SW[9:6]+BCD1[0];
		
		if(addrOut0 <= 5'd9) begin
			BCD0 = addrOut0[3:0];
			BCD1 = 4'b0000;
		end
		else begin
			BCD0 = addrOut0[3:0] - 4'd10;
			BCD1 = 4'b0001;
		end
		
		if(addrOut1 <= 5'd9) begin
			BCD2 = addrOut1[3:0];
			BCD3 = 4'b0000;
		end
		else begin
			BCD2 = addrOut1[3:0] - 4'd10;
			BCD3 = 4'b0001;
		end
	end
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