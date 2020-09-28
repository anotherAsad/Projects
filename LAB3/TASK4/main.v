module d_latch(Q, D, EN);
	output reg Q;
	input  D, EN;
	
	always @(EN, D)
		if(EN)
			Q = D;
endmodule

module dFFR(Q, D, CLK);
	output reg Q;
	input  D, CLK;
	
	always @(posedge CLK)
		Q = D;
endmodule

module main(LEDG, SW, KEY);
	output [2:0] LEDG;
	input  [0:0] SW;
	input  [3:3] KEY;
	
	d_latch	DLTH(LEDG[2], SW, ~KEY);		// POS level triggered
	dFFR	DFF0(LEDG[1], SW, ~KEY);		// Rising  Edge Triggered
	dFFR	DFF1(LEDG[0], SW,  KEY);		// Falling Edge Triggered
endmodule

module testbench;
	reg  CLK, D;
	wire Q1, Q2, Q3;
	
	main M0({Q1, Q2, Q3}, D, ~CLK);
	
	initial begin
		$display("D CLK: Q1, Q2, Q3");
		$monitor("%d   %d:  %d, %d,  %d", CLK, D, Q1, Q2, Q3);
		$dumpfile("test.vcd");
		$dumpvars(0, testbench);
		
		#0 D = 0; CLK = 0;
		#1 D = 0; CLK = 0;
		#1 D = 0; CLK = 0;
		#1 D = 1; CLK = 0;
		
		#1 D = 1; CLK = 1;
		#1 D = 0; CLK = 1;
		#1 D = 1; CLK = 1;
		#1 D = 0; CLK = 1;
		#1 D = 0; CLK = 1;
		
		#1 D = 0; CLK = 0;
		#1 D = 1; CLK = 0;
		#1 D = 0; CLK = 0;
		#1 D = 1; CLK = 0;
		#1 D = 0; CLK = 0;
		
		#1 D = 0; CLK = 1;
		#1 D = 1; CLK = 1;
		#1 D = 0; CLK = 1;
		#1 D = 1; CLK = 1;
		#1 D = 1; CLK = 0;
		
		#1 D = 0; CLK = 0;
		#1 D = 0; CLK = 0;
		#1 D = 0; CLK = 0;
		#1 D = 0; CLK = 0;
	end
endmodule 


