module d_latch(Q, D, CLK);
	output Q;
	input  D, CLK;
	wire   S, R, Qa, Qb;
	
	assign Qa = ~(Qb & S);
	assign Qb = ~(Qa & R);
	assign S  = ~(CLK & D);
	assign R  = ~(CLK & ~D);
	
	assign Q = Qa;
endmodule 

module main(LEDG, SW, KEY);
	output [0:0] LEDG;
	input  [0:0] SW;
	input  [3:3] KEY;
	d_latch D0(LEDG[0], SW, ~KEY);
endmodule 