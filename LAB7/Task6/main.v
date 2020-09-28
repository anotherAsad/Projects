module loaderFSM(lock, char, clk, reset);	// This FSM has no input
	output reg lock;
	output reg [6:0] char;
	reg [3:0] state;
	input clk, reset;
	
	parameter [3:0] H = 4'd0, E = 4'd1, L0 = 4'd2, L1 = 4'd3, O = 4'd4, STOP = 4'd5;
	
	// Sequential cloud.
	always @(posedge clk or negedge reset) begin
		if(~reset)
			state <= H;
		else
			case(state)
				H : state <= E;
				E : state <= L0;
				L0: state <= L1;
				L1: state <= O;
				O : state <= STOP;
				STOP: state <= STOP;
				default: state <= STOP;
			endcase
	end
	
	// Combinational Cloud: Output.
	always @(state) begin
		case(state)
			H : {lock, char} <= 8'b00001001;
			E : {lock, char} <= 8'b00000110;
			L0: {lock, char} <= 8'b01000111;
			L1: {lock, char} <= 8'b01000111;
			O : {lock, char} <= 8'b01000000;
			STOP: {lock, char} <= 8'hFF;
			
			default: {lock, char} <= 8'b00001001;
		endcase
	end
endmodule

module tickerShift(out4, out3, out2, out1, out0, in, lock, clk, reset);
	output reg [6:0] out4, out3, out2, out1, out0;
	input  [6:0] in;
	input  lock, clk, reset;
	
	always @(posedge clk or negedge reset) begin
		if(~reset) 
			{out4, out3, out2, out1, out0} = 35'h7FFFFFFFF;
		else begin
			out4 <= out3;
			out3 <= out2;
			out2 <= out1;
			out1 <= out0;
			out0 <= (lock) ? out4: in;
		end
	end
endmodule

module main(HEX3, HEX2, HEX1, HEX0, LEDG, LEDR, KEY[3], SW, CLOCK_50);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	output [0:0] LEDR;
	output [6:0] LEDG;
	input  [3:3] KEY;
	input  [0:0] SW, CLOCK_50;
	
	wire clk, lock;
	wire [6:0] load;
	
	assign LEDR[0] = lock;
	
	downClocker CLK0(clk, 26'd24999999, SW, CLOCK_50, KEY[3]);
	loaderFSM   FSM0(lock, load, clk, KEY[3]);
	tickerShift TSR0(HEX3, HEX2, HEX1, HEX0, LEDG, load, lock, clk, KEY[3]);
endmodule
