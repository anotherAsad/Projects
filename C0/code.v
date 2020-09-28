`include "cpu.v"
`include "misc.v"

module ROM(instr, addr);
	output reg [20:0] instr;
	input  [7:0] addr;
	
	always @(*) begin
		case (addr)
			8'd00	: instr = 21'b001011100000000000000;
			8'd01	: instr = 21'b011000000000000000000;
			8'd02	: instr = 21'b011000001100000000000;
			8'd03	: instr = 21'b111000001101100000001;
			8'd04	: instr = 21'b110000000000001100000;
			8'd05	: instr = 21'b101100000001100001010;
			8'd06	: instr = 21'b001001100000000000010;
			8'd07	: instr = 21'b001011100000000000110;
			default	: instr = {2'b01, 1'b0, 4'b0111, 3'b000, 3'b000, 8'b00000000};
		endcase
	end
endmodule

module system(
	output [07:0] R0, R1, R2, R3, R4, R5, R6, R7, Addr, FLAGS,
	input  manualLoad, CLK
);
	wire [20:0] INS, INS_PORT;
	assign INS_PORT = manualLoad ? {2'b00, 1'b1, 4'b0111, 3'b000, 3'b000, 8'b00000000}: INS;
	pinAbstractedCPU CPU0(Addr, FLAGS, R0, R1, R2, R3, R4, R5, R6, R7, INS_PORT, CLK);
	ROM              ROM0(INS, Addr);
endmodule


module main(
	output [7:0] LEDG, LEDR,
	output [6:0] HEX3, HEX2, HEX1, HEX0,
	input  [9:6] SW,
	input  [3:3] KEY
);
	wire [07:0] bin, R0, R1, R2, R3, R4, R5, R6, R7;
	wire [03:0] bcd2, bcd1, bcd0;
	
	bytemux8 binMux(bin, R0, R1, R2, R3, R4, R5, R6, R7, SW[8], SW[7], SW[6]);
	binToBCD8bit DEC0(bcd2, bcd1, bcd0, bin);
	bcdToSevSeg  DEC1(HEX0, bcd0);
	bcdToSevSeg  DEC2(HEX1, bcd1);
	bcdToSevSeg  DEC3(HEX2, bcd2);
	bcdToSevSeg  DEC4(HEX3, 4'd0);
	
	system S0(
		.R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7),
		.Addr(LEDR[7:0]),
		.FLAGS(LEDG[7:0]),
		.manualLoad(SW[9]), .CLK(~KEY[3])
	);
endmodule

module testbench;
	wire [7:0] LEDG, LEDR;
	wire [6:0] HEX3, HEX2, HEX1, HEX0;
	reg  [9:6] SW;
	reg  [3:3] KEY;
	
	integer i;
	
	main M0(LEDG, LEDR, HEX3, HEX2, HEX1, HEX0, SW, KEY);
	// 7 seg codes: 64 => 0; 121 => 1; 36 => 2;
	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0, testbench);
		
		for(i=0; i<50; i=i+1) begin
			SW[9] = !i;
			SW[8:6] = {3'b000};
			#1 $display("\nRESET: %d", SW[9]);
			#1 $display("%d\t%d\t%d\t%d\t%b\t%d\t%d", HEX3, HEX2, HEX1, HEX0, LEDG, LEDR, KEY);
			#1 KEY = 0;
			#1 $display("%d\t%d\t%d\t%d\t%b\t%d\t%d", HEX3, HEX2, HEX1, HEX0, LEDG, LEDR, KEY);
			#1 KEY = 1;
			#1 $display("%d\t%d\t%d\t%d\t%b\t%d\t%d", HEX3, HEX2, HEX1, HEX0, LEDG, LEDR, KEY);
			#1 KEY = 0;
			#1 $display("%d\t%d\t%d\t%d\t%b\t%d\t%d", HEX3, HEX2, HEX1, HEX0, LEDG, LEDR, KEY);
		end
	end
endmodule
/*
module testbench;
	wire [07:0] bin, R0, R1, R2, R3, R4, R5, R6, R7, Addr, FLAGS;
	wire [20:0] INS, INS_PORT;
	reg  RESET, CLK;
	
	integer i;
	
	bytemux8 binMux(bin, R0, R1, R2, R3, R4, R5, R6, R7, 1'b0, 1'b0, 1'b0);
	
	system S0(
		.R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7),
		.Addr(Addr),
		.FLAGS(FLAGS),
		.manualLoad(RESET), .CLK(CLK)
	);
	
	initial begin
		$display("REG0\tREG1\tFLAGS\t\tADDR\tCLK");
		
		for(i=0; i<10; i=i+1) begin
			RESET = !i;
			#1 $display("\nRESET: %d", RESET);
			#1 $display("%d\t%d\t%b\t%d\t%d", bin, R1, FLAGS, Addr, CLK);
			#1 CLK = 0;
			#1 $display("%d\t%d\t%b\t%d\t%d", bin, R1, FLAGS, Addr, CLK);
			#1 CLK = 1;
			#1 $display("%d\t%d\t%b\t%d\t%d", bin, R1, FLAGS, Addr, CLK);
			#1 CLK = 0;
			#1 $display("%d\t%d\t%b\t%d\t%d", bin, R1, FLAGS, Addr, CLK);
		end
	end
endmodule
*/
//   [X X] [X] [X X X X] [X X X] [X X X] [X X X | X X X X X]
// INSTYPE I/R  OPCODE   TGT_REG  AMUX    BMUX  | IMM
//	
//	INSTYPE: 00->JMP, 01->MOV, 10->CMP, 11->MATH
//  I/R    : 0->BREG, 1->IMM
