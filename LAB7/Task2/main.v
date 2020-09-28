module main(z, state, w, reset, clk);	// Reset is active low
	output z;
	output reg [3:0] state;
	input  w, reset, clk;
	reg   [3:0] driver;
	
	parameter A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011, E = 4'b0100,
			  F = 4'b0101, G = 4'b0110, H = 4'b0111, I = 4'b1000;
	
	// Combinational cloud; driver.
	always @(w, state) begin
		case(state)
			A: driver <= (~w ? B: F);
			
			B: driver <= (~w ? C: F);
			C: driver <= (~w ? D: F);
			D: driver <= (~w ? E: F);
			E: driver <= (~w ? E: F);
			
			F: driver <= ( w ? G: B);
			G: driver <= ( w ? H: B);
			H: driver <= ( w ? I: B);
			I: driver <= ( w ? I: B);
			
			default: driver <= 4'bxxxx;
		endcase
	end
	
	// Sequential cloud.
	always @(posedge clk or negedge reset) begin
		if(~reset)
			state <= 4'b0000;
		else
			state <= driver;
	end
	
	// Combinational cloudlet; output.
	assign z = (state == E) | (state == I);
endmodule

module main0(HEX3, HEX2, HEX1, HEX0, LEDG, KEY, CLOCK_50);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	output [0:0] LEDG;
	input  [3:2] KEY;
	input  [0:0] CLOCK_50;
	
	wire   [0:0] clk;
	wire   [3:0] bin;
	
	downClocker DC0(clk, 26'd24999999, 1'b1, CLOCK_50, KEY[3]);
	bcdToSevSeg DEC(HEX0, bin);
	fsm  FSM0(LEDG, bin, ~KEY[2], KEY[3], clk);
	
	assign HEX1 = 7'h7F;
	assign HEX2= 7'h7F;
	assign HEX3 = 7'h7F;
endmodule
