module main(
	SRAM_DQ, SRAM_ADDR, SRAM_LB_N, SRAM_UB_N, SRAM_CE_N, SRAM_OE_N, SRAM_WE_N,
	LEDR,
	SW, CLOCK_50, KEY
	);
	inout  [15:0] SRAM_DQ;
	output [17:0] SRAM_ADDR;
	output SRAM_LB_N, SRAM_UB_N, SRAM_CE_N, SRAM_OE_N, SRAM_WE_N;
	
	output [4:0] LEDR;
	input  [9:0] SW;
	input  [3:3] KEY;
	input  CLOCK_50;
	
	//onboardSramInterface(lb, ub, ce, oe, we, dataIO, addrOut, addrIn, dataIn, wsig, clk);
	onboardSramInterface INTR0(SRAM_LB_N, SRAM_UB_N, SRAM_CE_N, SRAM_OE_N, SRAM_WE_N, SRAM_DQ, SRAM_ADDR, {13'b0, SW[9:5]}, {11'b0, SW[4:0]}, KEY[3], CLOCK_50);
	assign LEDR = SRAM_DQ[4:0];
endmodule

module onboardSramInterface(lb, ub, ce, oe, we, dataIO, addrOut, addrIn, dataIn, wsig, clk);
	output lb, ub, ce, oe, we;
	inout  reg [15:0] dataIO;
	output reg [17:0] addrOut;
	input  [17:0] addrIn;
	input  [15:0] dataIn;
	input  wsig, clk;
	
	assign {lb, ub, ce, oe} = 4'b0;
	assign we = wsig;
	
	always @(posedge clk) begin
		addrOut <= addrIn;
	end
	
	always @(posedge clk) begin
		if(~we) 
			dataIO = dataIn;
		else
			dataIO = 16'bz;
	end
endmodule
