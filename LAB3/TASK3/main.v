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

module dff_rising(Q, D, CLK);
	output Q;
	input  D, CLK;
	
	wire   midLatch;
	d_latch d0(midLatch, D, ~CLK);
	d_latch d1(Q, midLatch,  CLK);
endmodule

module main(LEDG, SW, KEY);
	output [0:0] LEDG;
	input  [0:0] SW;
	input  [3:3] KEY;
	
	dff_rising DFF(LEDG, SW, ~KEY);
endmodule 

module testbench;
	reg  CLK, D;
	wire Q;
	
	dff_rising DFF(Q, D, CLK);
	
	initial begin
		$display("D CLK: Q");
		$monitor("%d %d: %d", D, CLK, Q);
		
		#0 D = 0; CLK = 0;
		#1 D = 0; CLK = 1;
		#1 D = 0; CLK = 0;
		#1 D = 0; CLK = 1;
		#1 D = 1; CLK = 0;
		#1 D = 1; CLK = 1;
		#1 D = 1; CLK = 0;
		#1 D = 1; CLK = 1;
		#1 D = 0; CLK = 0;
		#1 D = 0; CLK = 1;
	end
endmodule 