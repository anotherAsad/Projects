module ALU(Out, FLG, A, B, opcode);
	output[7:0] Out, FLG;
	input [7:0] A, B;
	input [3:0] opcode;
	wire  [7:0] xorOut, andOut, ornOut, mathOut, BSLOut, BSROut, ROLOut, ROROut;
	wire  w0;

	xorCKT  X1(xorOut, A, B);
	andCKT  A1(andOut, A, B);
	ornCKT  O1(ornOut, A, B, opcode[3]);
	mathCKT M(FLG[0], FLG[1], mathOut, opcode[3], A, B);	// Opcode[3] is addition/subtraction and OR/NOR bit

	bitshiftLeft  BSL(BSLOut, B);
	bitshiftRight BSR(BSROut, B);
	rotateLeft  ROL(ROLOut, B);
	rotateRight ROR(ROROut, B);

	bytemux8 MX(Out, mathOut, xorOut, andOut, ornOut, BSLOut, BSROut, ROLOut, ROROut, opcode[2], opcode[1], opcode[0]);
	nor zerocheck(FLG[3], Out[0], Out[1], Out[2], Out[3], Out[4], Out[5], Out[6], Out[7]);

	buf b0(FLG[2], mathOut[7]);							// Sign Bit handle
	not n0(w0, FLG[3]);
	and a0(FLG[4], w0, FLG[0]);
	or  o0(FLG[5], FLG[2], FLG[3]);
	buf b1(FLG[6], 1'b1);
	buf b2(FLG[7], 1'b0);
endmodule

/*
OPCODES for ALU
0000 - ADD
X001 - XOR
X010 - AND
0011 - OR
1011 - NOR
X100 - SHL
X101 - SHR
X110 - ROL
X111 - ROR
1000 - SUB

Carry and overfow will always be available from adder CKT

FLG[0] - Carry												; JC, JAE, JNB ; ~~ JNC, JNAE, JB
FLG[1] - Overflow											; JO		   ; ~~ JNO
FLG[2] - sign bit of output									; JS, JL, JNGE ; ~~ JNS, JNL, JGE
FLG[3] - Out is Zero (works with AND ORN XOR)   			; JZ, JEQ      ; ~~ JNZ, JNEQ
FLG[4] - CY.~ZRO											; JA, JNBE     ; ~~ JNA, JBE
FLG[5] - SGN+ZRO											; JLE, JNG	   ; ~~ JNLE, JG
FLG[6] - 1													; JMP
FLG[7] - 0													; CONT

      ____________
     |            |
     |            |
--/--|A        RES|--/--
     |            |
--/--|B      FLAGS|--/--
     |            |
--/--|OPCODE      |
     |            |
     |____________|


*/

