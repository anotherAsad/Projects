module spram(q, addr, d, wren, clk);	// Check Chip planner to see an M4K used.
	output [7:0] q;
	input  [7:0] d;
	input  [4:0] addr;
	input  wren, clk;
	
	reg [7:0] ram [31:0];
	reg [4:0] addrLine;
	
	assign q = ram[addrLine];
	
	always @(posedge clk) begin
		addrLine = addr;
		if(wren)
			ram[addrLine] = d;
	end
endmodule

module main(HEX3, HEX2, HEX1, HEX0, LEDR, KEY, SW, CLOCK_50);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	output [7:0] LEDR;
	input  [3:3] KEY;
	input  [9:0] SW;
	input  CLOCK_50;
	
	wire  [7:0] data;
	wire  [3:0] bcd2, bcd1, bcd0;
	
	assign data = {SW[7:5], SW[9:5]};
	assign HEX3 = 7'h7F;
	
	spram	spram_inst (
		.addr ( SW[4:0] ),
		.clk ( CLOCK_50 ),
		.d ( data ),
		.wren ( ~KEY ),
		.q ( LEDR )
	);

	binToBCD8bit DEC0(bcd2, bcd1, bcd0, LEDR);
	bcdToSevSeg  DEC1(HEX0, bcd0);
	bcdToSevSeg  DEC2(HEX1, bcd1);
	bcdToSevSeg  DEC3(HEX2, bcd2);
endmodule
