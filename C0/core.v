module instPtr(Addr, PL, PL_E, CLK);
	output [7:0] Addr;
	input  [7:0] PL;
	input  CLK, PL_E;		
							
	wire   [7:0] regToInc, muxToReg;
	
	bytemux2 MX(muxToReg, Addr, PL, PL_E);
	register RG(regToInc, muxToReg, CLK);
	byteIncrementer inc(Addr, regToInc);
endmodule

module core(Addr, FLAGS,
			R0, R1, R2, R3, R4, R5, R6, R7,

			MEM_INST, ALU_INST, JMP_INST,
			MS1, MS0,		// Mode Select for RegBank. 00->ALU, 01->REG, 10->IMM, 11->loline/MainMEM
			IRS,			// Immeditate or Register Select. Chooses between BMUX8 and IMM inputs for ALU ARG B.
			RS2, RS1, RS0,	// Target Register select lines. Data will be written to this register.
			AR2, AR1, AR0,	// AR stands or AMUX and RegBank select lines.
			BS2, BS1, BS0,  // BS stands for BMUX input select lines
			OP, IMM,		// OP (4 bits) is ALU opcode or BranchUnit Instruction.
			CLK
			);
	output [7:0] R0, R1, R2, R3, R4, R5, R6, R7, Addr, FLAGS;
	input  [7:0] IMM;
	input  [3:0] OP;
	input  MEM_INST, ALU_INST, JMP_INST, RS2, RS1, RS0, AR2, AR1, AR0, BS2, BS1, BS0, CLK, IRS, MS1, MS0;
	// AREG is output from the A MUX, that feeds both REGBANK and ALU-ARG_A
	// BREG is output from the B MUX, that indirectly feeds the ALU-ARG_B. An intermediate 2x1 bytemux chooses between
	// Register (BREG) or immediate (IMM) input.

	wire [7:0] FLG, ALU, AREG, BREG, BLINE;
	wire JMP, PL_A, PL_E, FLG_E;	// PL_A: Parallel Load Available.

	regBank	RB0(R0, R1, R2, R3, R4, R5, R6, R7, ALU, AREG, IMM, MS1, MS0, RS2, RS1, RS0, CLK, MEM_INST);
	bytemux8	AMUX8(AREG, R0, R1, R2, R3, R4, R5, R6, R7, AR2, AR1, AR0);
	bytemux8	BMUX8(BREG, R0, R1, R2, R3, R4, R5, R6, R7, BS2, BS1, BS0); // BS stands for B_Input select lines
	bytemux2	BMUX2(BLINE, BREG, IMM, IRS);
	ALU		ALU0(ALU, FLG, AREG, BLINE, OP);					// ALU stands for ALU output, ALU0 is the actual.
	and		FLGN(FLG_E, ALU_INST, CLK);
	register	flags(FLAGS,FLG, FLG_E);		// FLG is output bus from ALU, FLAGS is the register.
	
	bitmux8	jmpMux(JMP, FLAGS[0], FLAGS[1], FLAGS[2], FLAGS[3], FLAGS[4], FLAGS[5], FLG[6], FLG[7], OP[2], OP[1], OP[0]);
	xnor		jmpXnor(PL_A, JMP, OP[3]);
	and		JMPN(PL_E, PL_A, JMP_INST);						// JMP eNable
	instPtr  PC(Addr, IMM, PL_E, CLK);		// Parallel load to be given as IMM.
endmodule
			
/* INSTRUCTION BLOCK
		MEM_INST = 0; ALU_INST = 0; JMP_INST = 1;
		MS1 = 0; MS0 = 0;			// Mode Select for RegBank. 00->ALU, 01->REG, 10->IMM, 11->loline/MainMEM
		IRS = 0;					// Immeditate or Register Select. Chooses between BMUX8 and IMM inputs for ALU ARG B.
		RS2 = 0; RS1 = 0; RS0 = 0;	// Target Register select lines. Data will be written to this register.
		AR2 = 0; AR1 = 0; AR0 = 0;	// AR stands or AMUX and RegBank select lines.
		BS2 = 0; BS1 = 0; BS0 = 0;  // BS stands for BMUX input select lines
		OP = 4'b0111; IMM = 0;		// OP (4 bits) is ALU opcode or BranchUnit Instruction.
*/
