module ROM(instr, addr);
	output reg [20:0] instr;
	input  [7:0] addr;
	
	always @(*) begin
		case (addr)
			8'd00: instr = 21'b011000000000000000000;
			8'd01: instr = 21'b011000001100000000000;
			8'd02: instr = 21'b111000000000000001101;
			8'd03: instr = 21'b111000001101100000001;
			8'd04: instr = 21'b101100000001100001111;
			8'd05: instr = 21'b001001100000000000001;
			8'd06: instr = 21'b001011100000000000101;

			default: instr = {2'b01, 1'b0, 4'b0100, 3'b000, 3'b001, 8'b00010100};
		endcase
	end
endmodule

module system(
	output [07:0] R0, R1, R2, R3, R4, R5, R6, R7, Addr, FLAGS,
	output [20:5] INS_OUT,
	input  RESET, CLK
);	
	wire [20:0] INS, INS_PORT;
	
	assign INS_PORT = RESET ? {2'b00, 1'b0, 4'b0111, 3'b000, 3'b000, 8'b11111111}: INS;
	pinAbstractedCPU CPU0(Addr, FLAGS, R0, R1, R2, R3, R4, R5, R6, R7, INS_PORT, CLK);
	ROM              ROM0(INS, Addr);
	assign INS_OUT = INS_PORT[20:5];
endmodule

module main(
	output [7:0] LEDG, LEDR,
	output [6:0] HEX3, HEX2, HEX1, HEX0,
	input  [9:6] SW,
	input  CLOCK_50
);
	wire [07:0] bin, R0, R1, R2, R3, R4, R5, R6, R7, Addr, Flags;
	wire [03:0] bcd2, bcd1, bcd0;
	wire pulse;
	
	bytemux8     binMux(bin, R0, R1, R2, R3, R4, R5, R6, Addr, SW[8], SW[7], SW[6]);
	binToBCD8bit DEC0(bcd2, bcd1, bcd0, bin);
	bcdToSevSeg  DEC1(HEX0, bcd0);
	bcdToSevSeg  DEC2(HEX1, bcd1);
	bcdToSevSeg  DEC3(HEX2, bcd2);
	bcdToSevSeg  DEC4(HEX3, 4'd0);
	
	downClocker DC0(pulse, 27'd12499999, 1'b1, CLOCK_50, 1'b1);
	
	system S0(
		.R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7),
		.Addr(Addr),
		.FLAGS(Flags),
		.INS_OUT({LEDR, LEDG}),
		.RESET(SW[9]),
		.CLK(pulse)
	);
endmodule

	//   [X X] [X] [X X X X] [X X X] [X X X] [X X X | X X X X X]
	// INSTYPE I/R  OPCODE   TGT_REG  AMUX    BMUX  | IMM
	//	
	//	INSTYPE: 00->JMP, 01->MOV, 10->CMP, 11->MATH
	//  I/R    : 0->BREG, 1->IMM