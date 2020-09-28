module stuckFlop(Q, D, clk, reset);
	output reg Q;
	reg lock;
	input  D, clk, reset;
	
	always @(posedge clk or negedge reset) begin
		if(~reset)
			{Q, lock} <= 2'b00;
		else if(D & ~lock)
			{Q, lock} <= 2'b11;
		else if(~D & lock)
			{Q, lock} <= 2'b00;
		else
			{Q, lock} <= {1'b0, lock};
	end
endmodule

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

module speedControlFSM(limit, state, in1, in0, clk, reset);
	output reg [26:0] limit;
	input  in1, in0, clk, reset;
	
	output reg  [2:0] state;
	reg  [2:0] driver;
	
	// Combinational Cloud: Driver
	always @(in0, in1, state) begin
		case(state)
			3'b000: driver <= in1? 3'b001: 3'b000;					// Quarter State
			3'b001: driver <= in1? 3'b010: (in0? 3'b000: 3'b001);	// Half State
			3'b010: driver <= in1? 3'b011: (in0? 3'b001: 3'b010);	// Unit State
			3'b011: driver <= in1? 3'b100: (in0? 3'b010: 3'b011);	// Double State
			3'b100: driver <= in0? 3'b011: 3'b100;					// Quad State
			
			default: driver <= 3'b010;
		endcase
	end
	
	// Sequential Cloud
	always @(posedge clk or negedge reset) begin
		if(~reset)
			state <= 3'b010;
		else
			state <= driver;
	end
	
	// Combinational Cloud: Output
	always @(*) begin
		case(state)
			3'b000: limit <= 27'd06249999;
			3'b001: limit <= 27'd12499999;
			3'b010: limit <= 27'd24999999;
			3'b011: limit <= 27'd49999999;
			3'b100: limit <= 27'd99999999;
			
			default: limit <= 27'd24999999;
		endcase
	end
endmodule
	
module main(HEX3, HEX2, HEX1, HEX0, LEDG, LEDR, KEY, SW, CLOCK_50);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	output [0:0] LEDR;
	output [2:0] LEDG;
	input  [3:1] KEY;
	input  [0:0] SW, CLOCK_50;
	
	wire clk, lock, in1, in2;
	wire [6:0] load;
	wire [26:0] limit;
	assign LEDR[0] = lock;
	
	stuckFlop  SF0(in1, ~KEY[2], CLOCK_50, KEY[3]);
	stuckFlop  SF1(in2, ~KEY[1], CLOCK_50, KEY[3]);

	speedControlFSM FSM0(limit, LEDG, in1, in2, CLOCK_50, KEY[3]);
	downClocker CLK0(clk, limit, SW, CLOCK_50, KEY[3]);
	loaderFSM   FSM1(lock, load, clk, KEY[3]);
	tickerShift TSR0(HEX3, HEX2, HEX1, HEX0, _, load, lock, clk, KEY[3]);
endmodule
