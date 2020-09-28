// Adder/Subtractor, XOR, AND, OR, bitshift_left, bitshift_right, rotate_left,rotate_right

// mathCKT Uses implicit XORs
module halfAdder(S, C, A, B);
	output S, C;
	input  A, B;

	xor x0(S, A, B);
	and a0(C, A, B);
endmodule

module byteIncrementer(R, I);
	output[7:0] R;
	input [7:0] I;
	supply1     One;
	
	wire  [7:0] T;		// Tranfer wires

	halfAdder h0(R[0], T[0], I[0], One);
	halfAdder h1(R[1], T[1], I[1], T[0]);
	halfAdder h2(R[2], T[2], I[2], T[1]);
	halfAdder h3(R[3], T[3], I[3], T[2]);
	halfAdder h4(R[4], T[4], I[4], T[3]);
	halfAdder h5(R[5], T[5], I[5], T[4]);
	halfAdder h6(R[6], T[6], I[6], T[5]);
	halfAdder h7(R[7], T[7], I[7], T[6]);
endmodule

module fAddr(outC, sum, inC, A, B);
	output outC, sum;
	input  inC, A, B;
	wire   abSum, abCarry, hA2Carry;

	xor x1(abSum, A, B);
	and a1(abCarry, A, B);
	xor x2(sum, abSum, inC);
	and a2(hA2Carry, abSum, inC);

	or  o1(outC, hA2Carry, abCarry);
endmodule

module mathCKT(outC, ovFL, sum, SUB, A, B);
	output outC, ovFL;			// ovFL is overflow flag
	output [7:0] sum;
	input  SUB;
	input  [7:0] A, B;
	
	wire   [6:0] cp;			// Carry Propogation Wire
	wire   [7:0] xCon;			// XOR to B connector
	
	xor x0(xCon[0], B[0], SUB);
	xor x1(xCon[1], B[1], SUB);
	xor x2(xCon[2], B[2], SUB);
	xor x3(xCon[3], B[3], SUB);
	xor x4(xCon[4], B[4], SUB);
	xor x5(xCon[5], B[5], SUB);
	xor x6(xCon[6], B[6], SUB);
	xor x7(xCon[7], B[7], SUB);

	fAddr f0(cp[0], sum[0], SUB  , A[0], xCon[0]);
	fAddr f1(cp[1], sum[1], cp[0], A[1], xCon[1]);
	fAddr f2(cp[2], sum[2], cp[1], A[2], xCon[2]);
	fAddr f3(cp[3], sum[3], cp[2], A[3], xCon[3]);
	fAddr f4(cp[4], sum[4], cp[3], A[4], xCon[4]);
	fAddr f5(cp[5], sum[5], cp[4], A[5], xCon[5]);
	fAddr f6(cp[6], sum[6], cp[5], A[6], xCon[6]);
	fAddr f7(outC , sum[7], cp[6], A[7], xCon[7]);

	xor ovF(ovFL, cp[6], outC);		// Overflow Check
endmodule

// R for Result
module xorCKT(R, A, B);
	input [7:0] A, B;
	output[7:0] R;

	xor x0(R[0], A[0], B[0]);
	xor x1(R[1], A[1], B[1]);
	xor x2(R[2], A[2], B[2]);
	xor x3(R[3], A[3], B[3]);
	xor x4(R[4], A[4], B[4]);
	xor x5(R[5], A[5], B[5]);
	xor x6(R[6], A[6], B[6]);
	xor x7(R[7], A[7], B[7]);
endmodule	

module ornCKT(R, A, B, S0);
	input [7:0] A, B;
	output[7:0] R;
	wire  [7:0] O;
	input S0;

	or  x0(O[0], A[0], B[0]);
	or  x1(O[1], A[1], B[1]);
	or  x2(O[2], A[2], B[2]);
	or  x3(O[3], A[3], B[3]);
	or  x4(O[4], A[4], B[4]);
	or  x5(O[5], A[5], B[5]);
	or  x6(O[6], A[6], B[6]);
	or  x7(O[7], A[7], B[7]);

	xor y0(R[0], S0, O[0]);
	xor y1(R[1], S0, O[1]);
	xor y2(R[2], S0, O[2]);
	xor y3(R[3], S0, O[3]);
	xor y4(R[4], S0, O[4]);
	xor y5(R[5], S0, O[5]);
	xor y6(R[6], S0, O[6]);
	xor y7(R[7], S0, O[7]);
endmodule

module andCKT(R, A, B);
	input [7:0] A, B;
	output[7:0] R;

	and x0(R[0], A[0], B[0]);
	and x1(R[1], A[1], B[1]);
	and x2(R[2], A[2], B[2]);
	and x3(R[3], A[3], B[3]);
	and x4(R[4], A[4], B[4]);
	and x5(R[5], A[5], B[5]);
	and x6(R[6], A[6], B[6]);
	and x7(R[7], A[7], B[7]);
endmodule

module bitshiftLeft(R, A);
	input [7:0] A;
	output[7:0] R;
	
	buf b0(R[7], A[6]);
	buf b1(R[6], A[5]);
	buf b2(R[5], A[4]);
	buf b3(R[4], A[3]);
	buf b4(R[3], A[2]);
	buf b5(R[2], A[1]);
	buf b6(R[1], A[0]);
	buf b7(R[0], 1'b0);
endmodule

module bitshiftRight(R, A);
	input [7:0] A;
	output[7:0] R;
	
	buf b0(R[7], 1'b0);
	buf b1(R[6], A[7]);
	buf b2(R[5], A[6]);
	buf b3(R[4], A[5]);
	buf b4(R[3], A[4]);
	buf b5(R[2], A[3]);
	buf b6(R[1], A[2]);
	buf b7(R[0], A[1]);
endmodule

module rotateLeft(R, A);
	input [7:0] A;
	output[7:0] R;
	
	buf b0(R[7], A[6]);
	buf b1(R[6], A[5]);
	buf b2(R[5], A[4]);
	buf b3(R[4], A[3]);
	buf b4(R[3], A[2]);
	buf b5(R[2], A[1]);
	buf b6(R[1], A[0]);
	buf b7(R[0], A[7]);
endmodule

module rotateRight(R, A);
	input [7:0] A;
	output[7:0] R;
	
	buf b0(R[7], A[0]);
	buf b1(R[6], A[7]);
	buf b2(R[5], A[6]);
	buf b3(R[4], A[5]);
	buf b4(R[3], A[4]);
	buf b5(R[2], A[3]);
	buf b6(R[1], A[2]);
	buf b7(R[0], A[1]);
endmodule
