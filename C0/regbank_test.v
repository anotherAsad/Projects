`include "control.v"
`include "register.v"

module testbench;
	wire [7:0] R0, R1, R2, R3, R4, R5, R6, R7;
	reg  [7:0] ALU, REG, IMM;
	reg  MS1, MS0, RS2, RS1, RS0, CLK, E;
	
	regBank RB0(R0, R1, R2, R3, R4, R5, R6, R7, ALU, REG, IMM, MS1, MS0, RS2, RS1, RS0, CLK, E);
	
	initial begin
		{ALU, REG, IMM} = {8'd0, 8'd0, 8'd10};
		{MS1, MS0} = 2'b10;
		{RS2, RS1, RS0} = 3'b000;
		E = 1;
		
		#1 CLK = 0;
		#1 $display("%d\t%d", R0, CLK);
		#1 CLK = 1;
		#1 $display("%d\t%d", R0, CLK);
		#1 CLK = 0;
		#1 $display("%d\t%d", R0, CLK);
	end
endmodule

/*
module regBank(R0, R1, R2, R3, R4, R5, R6, R7, ALU, REG, IMM, MS1, MS0, RS2, RS1, RS0, CLK, E);
	// E is the global enable; when 0, the decoder outputs 0, disabling all register inputs.
	output [7:0] R0, R1, R2, R3, R4, R5, R6, R7;
	input  [7:0] ALU, REG, IMM;
	input  MS0, MS1, RS0, RS1, RS2, E, CLK;

	supply0 [7:0] loline;	// Might one day replace with MEM.
	
	wire   [7:0] MXOUT;
	wire   R0E, R1E, R2E, R3E, R4E, R5E, R6E, R7E, En; 		// Register Enables
	
	and	   a0(En, E, CLK);									// Decoder Enable for incoming clock
	bitdecoder8 DEC(R0E, R1E, R2E, R3E, R4E, R5E, R6E, R7E, RS2, RS1, RS0, En);
	bytemux4	MX4(MXOUT, ALU, REG, IMM, loline, MS1, MS0);
	
	register RG0(R0, MXOUT, R0E);
	register RG1(R1, MXOUT, R1E);
	register RG2(R2, MXOUT, R2E);
	register RG3(R3, MXOUT, R3E);
	register RG4(R4, MXOUT, R4E);
	register RG5(R5, MXOUT, R5E);
	register RG6(R6, MXOUT, R6E);
	register RG7(R7, MXOUT, R7E);
endmodule
*/
