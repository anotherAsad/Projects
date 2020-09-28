module main(
	output [6:0] HEX3, HEX2, HEX1, HEX0,
	input  [9:0] SW,
	input  [3:2] KEY,
	input  CLOCK_50
);
	wire clk;
	wire [7:0] q_sig;
	reg  [4:0] rdaddress_sig;
	
	ramlpm	ramlpm_inst (
		.clock ( CLOCK_50 ),
		.data ( {SW[7:5], SW[9:5]} ),
		.rdaddress ( rdaddress_sig ),
		.wraddress ( SW[4:0] ),
		.wren ( ~KEY[3] ),
		.q ( q_sig )
	);
	
	// Address sweep counter
	always @(posedge clk or negedge KEY[2]) begin
		if(~KEY[2])
			rdaddress_sig <= 5'b0;
		else
			rdaddress_sig <= rdaddress_sig + 5'b1;
	end
	
	downClocker DCLK(clk, 27'd24999999, SW[0], CLOCK_50, KEY[2]);
	hexToSevSeg DEC0(HEX0, q_sig[3:0]);
	hexToSevSeg DEC1(HEX1, q_sig[7:4]);
	hexToSevSeg DEC2(HEX2, rdaddress_sig[3:0]);
	hexToSevSeg DEC3(HEX3, {3'b0, rdaddress_sig[4]});
endmodule
