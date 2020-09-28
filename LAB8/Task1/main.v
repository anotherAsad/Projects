module main(LEDR, KEY, SW, CLOCK_50);
	output [7:0] LEDR;
	input  [3:3] KEY;
	input  [9:0] SW;
	input  CLOCK_50;
	
	reg   [7:0] data;
	
	lpmram	lpmram_inst (
	.address ( SW[4:0] ),
	.clock ( CLOCK_50 ),
	.data ( data ),
	.wren ( ~KEY ),
	.q ( LEDR )
	);

	always @(*)
		data <= {SW[7:5], SW[9:5]};
endmodule
