module shiftReg(Q1, Q0, CLK, Reset, D);
	output reg [7:0] Q1, Q0;
	input  [7:0] D;
	input  CLK, Reset;
	
	always @(posedge CLK or negedge Reset) begin
		if(!Reset)
			{Q1, Q0} = {8'd0, 8'd0};
		else begin
			Q1 = Q0;
			Q0 = D;
		end
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

module main(HEX3, HEX2, HEX1, HEX0, KEY, SW);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [3:2] KEY;
	input  [7:0] SW;
	wire   [7:0] Q1, Q0;
	
	hexToSevSeg HDEC0(HEX0, Q0[3:0]);
	hexToSevSeg HDEC1(HEX1, Q0[7:4]);
	hexToSevSeg HDEC2(HEX2, Q1[3:0]);
	hexToSevSeg HDEC3(HEX3, Q1[7:4]);
	
	
	shiftReg SR0(Q1, Q0, ~KEY[3], KEY[2], SW);
endmodule 