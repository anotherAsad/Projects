module my_dlatch(Q, D, E);
	output Q;
	input D, E;
	
	wire wto1, back1, back2;
	wire notD;

	not  n0(notD, D);
	nand n1(Q, wto1, back1);
	nand n2(wto1, Q, back2);
	nand n3(back1, D, E);
	nand n4(back2, notD, E);
endmodule

module flipflop_old(Q, D, CLK);				// Falling edge triggered
	output Q;
	input  D, CLK;
	
	wire  notCLK, D1toD2;
	not n0(notCLK, CLK);
	
	my_dlatch D1(D1toD2, D, CLK);
	my_dlatch D2(Q, D1toD2, notCLK);
endmodule

module flipflop(Q, D, CLK);				// Falling edge triggered
	output reg Q;
	input  D, CLK;
	
	always @(negedge CLK)
		Q <= D;
endmodule

module register(out, in, CLK);
	output[7:0] out;
	input [7:0] in;
	input CLK;

	flipflop d0(out[0], in[0], CLK);
	flipflop d1(out[1], in[1], CLK);
	flipflop d2(out[2], in[2], CLK);
	flipflop d3(out[3], in[3], CLK);
	flipflop d4(out[4], in[4], CLK);
	flipflop d5(out[5], in[5], CLK);
	flipflop d6(out[6], in[6], CLK);
	flipflop d7(out[7], in[7], CLK);
endmodule

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

// Decoder Instruction: 
	

/*				TEST BENCH
module main();
	reg [7:0] D;
	reg  CLK;
	wire[7:0] O;

	register R(O, D, CLK);
	initial begin
		CLK = 0;
		$monitor("%d", O);
		D = 8'd123;
		#1
		CLK = 1;
		#1
		CLK = 0;
	end
endmodule
*/
