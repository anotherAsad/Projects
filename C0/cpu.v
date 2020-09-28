module pinAbstractedCPU(Addr, FLAGS, R0, R1, R2, R3, R4, R5, R6, R7, INS, CLK);
	// A rudimentary instruction decoder for the CPU core follows in the form of bufs, nors and xors.
	output [07:0] R0, R1, R2, R3, R4, R5, R6, R7, Addr, FLAGS;
	input  [20:0] INS;
	input   CLK;
	//   [X X] [X] [X X X X] [X X X] [X X X] [X X X | X X X X X]
	// INSTYPE I/R  OPCODE   TGT_REG  AMUX    BMUX  | IMM
	//	
	//	INSTYPE: 00->JMP, 01->MOV, 10->CMP, 11->MATH
	//  I/R    : 0->BREG, 1->IMM
	wire  MEM_INST, ALU_INST, JMP_INST, IRS, MS1, MS0;
	wire  w0, w1, w2;

	buf b0(ALU_INST, INS[20]);
	buf b1(MEM_INST, INS[19]);
	nor n0(JMP_INST, INS[20], INS[19]);

	xor  x0(w0, INS[20], INS[18]);
	xor  x1(w1, INS[19], INS[18]);
	nand n1(w2, INS[20], INS[19]);
	and  a0(MS1, w0, w2);
	and  a1(MS0, w1, w2);

	core C0(Addr, FLAGS,
			R0, R1, R2, R3, R4, R5, R6, R7,

			MEM_INST, ALU_INST, JMP_INST,
			MS1, MS0,			// Mode Select for RegBank. 00->ALU, 01->REG, 10->IMM, 11->loline/MainMEM
			INS[18],			// Immeditate or Register Select. Chooses between BMUX8 and IMM inputs for ALU ARG B.
			INS[13], INS[12], INS[11],	// Target Register select lines. Data will be written to this register.
			INS[10], INS[09], INS[08],	// AR stands for AMUX and RegBank select lines.
			INS[07], INS[06], INS[05],  // BS stands for BMUX input select lines
			INS[17:14], INS[7:0],		// OP (4 bits) is ALU opcode or BranchUnit Instruction.
			CLK
		);
endmodule
	//   [X X] [X] [X X X X] [X X X] [X X X] [X X X | X X X X X]
	// INSTYPE I/R  OPCODE   TGT_REG  AMUX    BMUX  | IMM
	//	
	//	INSTYPE: 00->JMP, 01->MOV, 10->CMP, 11->MATH
	// I/R    : 0->BREG, 1->IMM
