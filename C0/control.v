module bitmux8(out, A, B, C, D, E, F, G, H, S2org, S1org, S0org);
	output out;
	input  A, B, C, D, E, F, G, H, S0org, S1org, S2org;
	wire   S0inv, S1inv, S2inv;
	wire   [7:0] stat;

	not n0(S0inv, S0org);
	not n1(S1inv, S1org);
	not n2(S2inv, S2org);
	
	and A1(stat[0], A, S2inv, S1inv, S0inv);
	and A2(stat[1], B, S2inv, S1inv, S0org);
	and A3(stat[2], C, S2inv, S1org, S0inv);
	and A4(stat[3], D, S2inv, S1org, S0org);
	and A5(stat[4], E, S2org, S1inv, S0inv);
	and A6(stat[5], F, S2org, S1inv, S0org);
	and A7(stat[6], G, S2org, S1org, S0inv);
	and A8(stat[7], H, S2org, S1org, S0org);


	or O1(out, stat[7], stat[6], stat[5], stat[4], stat[3], stat[2], stat[1], stat[0]);			// Collector OR Gate
endmodule

module bitmux4(out, A, B, C, D, S1org, S0org);
	output out;
	input  A, B, C, D, S0org, S1org;
	wire   S0inv, S1inv;
	wire   [3:0] stat;

	not n0(S0inv, S0org);
	not n1(S1inv, S1org);

	and A1(stat[0], A, S1inv, S0inv);
	and A2(stat[1], B, S1inv, S0org);
	and A3(stat[2], C, S1org, S0inv);
	and A4(stat[3], D, S1org, S0org);

	or  O1(out, stat[3], stat[2], stat[1], stat[0]);
endmodule

module bitmux2(out, A, B, S0org);
	output out;
	input  A, B, S0org;
	wire   S0inv;
	wire   [1:0] stat;

	not n0(S0inv, S0org);

	and A1(stat[0], A, S0inv);
	and A2(stat[1], B, S0org);
	
	or  O1(out, stat[1], stat[0]);
endmodule

module bitmux16(out, in, S);
	output out;
	input  [0:15] in;
	input  [03:0] S;
	wire   [00:1] w;
	
	bitmux8 b0(w[0], in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7], S[2], S[1], S[0]);
	bitmux8 b1(w[1], in[8], in[9], in[10], in[11], in[12], in[13], in[14], in[15], S[2], S[1], S[0]);
	bitmux2 b3(out , w[0] , w[1] , S[3]);
endmodule

module bitmux256(out, in, S);
	output out;
	input  [0:255] in;
	input  [7:000] S;
	wire   [0:15] w;

	bitmux16 b0(w[00], in[000:015], S[3:0]);
	bitmux16 b1(w[01], in[016:031], S[3:0]);
	bitmux16 b2(w[02], in[032:047], S[3:0]);
	bitmux16 b3(w[03], in[048:063], S[3:0]);
	bitmux16 b4(w[04], in[064:079], S[3:0]);
	bitmux16 b5(w[05], in[080:095], S[3:0]);
	bitmux16 b6(w[06], in[096:111], S[3:0]);
	bitmux16 b7(w[07], in[112:127], S[3:0]);
	bitmux16 b8(w[08], in[128:143], S[3:0]);
	bitmux16 b9(w[09], in[144:159], S[3:0]);
	bitmux16 bA(w[10], in[160:175], S[3:0]);
	bitmux16 bB(w[11], in[176:191], S[3:0]);
	bitmux16 bC(w[12], in[192:207], S[3:0]);
	bitmux16 bD(w[13], in[208:223], S[3:0]);
	bitmux16 bE(w[14], in[224:239], S[3:0]);
	bitmux16 bF(w[15], in[240:255], S[3:0]);

	bitmux16 collectorMux(out, w, S[7:4]);
endmodule

module bytemux8(out, A, B, C, D, E, F, G, H, S2, S1, S0);
	output [7:0] out;
	input  [7:0] A, B, C, D, E, F, G, H;
	input  S0, S1, S2;

	bitmux8 mx0(out[0], A[0], B[0], C[0], D[0], E[0], F[0], G[0], H[0], S2, S1, S0);
	bitmux8 mx1(out[1], A[1], B[1], C[1], D[1], E[1], F[1], G[1], H[1], S2, S1, S0);
	bitmux8 mx2(out[2], A[2], B[2], C[2], D[2], E[2], F[2], G[2], H[2], S2, S1, S0);
	bitmux8 mx3(out[3], A[3], B[3], C[3], D[3], E[3], F[3], G[3], H[3], S2, S1, S0);
	bitmux8 mx4(out[4], A[4], B[4], C[4], D[4], E[4], F[4], G[4], H[4], S2, S1, S0);
	bitmux8 mx5(out[5], A[5], B[5], C[5], D[5], E[5], F[5], G[5], H[5], S2, S1, S0);
	bitmux8 mx6(out[6], A[6], B[6], C[6], D[6], E[6], F[6], G[6], H[6], S2, S1, S0);
	bitmux8 mx7(out[7], A[7], B[7], C[7], D[7], E[7], F[7], G[7], H[7], S2, S1, S0);
endmodule

module bytemux4(out, A, B, C, D, S1, S0);
	output [7:0] out;
	input  [7:0] A, B, C, D;
	input  S0, S1;

	bitmux4 mx0(out[0], A[0], B[0], C[0], D[0], S1, S0);
	bitmux4 mx1(out[1], A[1], B[1], C[1], D[1], S1, S0);
	bitmux4 mx2(out[2], A[2], B[2], C[2], D[2], S1, S0);
	bitmux4 mx3(out[3], A[3], B[3], C[3], D[3], S1, S0);
	bitmux4 mx4(out[4], A[4], B[4], C[4], D[4], S1, S0);
	bitmux4 mx5(out[5], A[5], B[5], C[5], D[5], S1, S0);
	bitmux4 mx6(out[6], A[6], B[6], C[6], D[6], S1, S0);
	bitmux4 mx7(out[7], A[7], B[7], C[7], D[7], S1, S0);
endmodule

module bytemux2(out, A, B, S0);
	output [7:0] out;
	input  [7:0] A, B;
	input  S0;

	bitmux2 mx0(out[0], A[0], B[0], S0);
	bitmux2 mx1(out[1], A[1], B[1], S0);
	bitmux2 mx2(out[2], A[2], B[2], S0);
	bitmux2 mx3(out[3], A[3], B[3], S0);
	bitmux2 mx4(out[4], A[4], B[4], S0);
	bitmux2 mx5(out[5], A[5], B[5], S0);
	bitmux2 mx6(out[6], A[6], B[6], S0);
	bitmux2 mx7(out[7], A[7], B[7], S0);
endmodule

module bitdecoder8(A, B, C, D, E, F, G, H, S2org, S1org, S0org, En);
	output A, B, C, D, E, F, G, H;
	input  S0org, S1org, S2org, En;
	wire   S0inv, S1inv, S2inv;

	not n0(S0inv, S0org);
	not n1(S1inv, S1org);
	not n2(S2inv, S2org);
	
	and A1(A, S2inv, S1inv, S0inv, En);
	and A2(B, S2inv, S1inv, S0org, En);
	and A3(C, S2inv, S1org, S0inv, En);
	and A4(D, S2inv, S1org, S0org, En);
	and A5(E, S2org, S1inv, S0inv, En);
	and A6(F, S2org, S1inv, S0org, En);
	and A7(G, S2org, S1org, S0inv, En);
	and A8(H, S2org, S1org, S0org, En);
endmodule
