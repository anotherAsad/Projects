module hexToSevSeg(out, in);
	output reg [6:0] out;
	input  [3:0] in;
	
	always @(*) begin
		case(in)
			4'h0: out = 7'b1000000;
			4'h1: out = 7'b1111001;
			4'h2: out = 7'b0100100;
			4'h3: out = 7'b0110000;
			4'h4: out = 7'b0011001;
			4'h5: out = 7'b0010010;
			4'h6: out = 7'b0000010;
			4'h7: out = 7'b1111000;
			4'h8: out = 7'b0000000;
			4'h9: out = 7'b0010000;
			4'hA: out = 7'b0001000;
			4'hB: out = 7'b0000011;
			4'hC: out = 7'b1000110;
			4'hD: out = 7'b0100001;
			4'hE: out = 7'b0000110;
			4'hF: out = 7'b0001110;
		endcase
	end
endmodule 

module downClocker(pulse, clk, reset, en);
	// Clocks down 50 MHz clock to 1Hz
	output reg pulse;
	input  clk, reset, en;
	reg [25:0] out;
		
	always @(posedge clk or negedge reset) begin
		if(~reset) begin
			out <= 26'd0;
			pulse <= 1'b0;
		end
		else if(en) begin
			out <= out + 26'd1;				// Combinational action 1
			if(out == 26'd24999999) begin	// Combinational action 2
				pulse <= ~pulse;
				out <= 26'd0;
			end
		end
	end
endmodule

module syncCounter(out, clk, reset, en);
	parameter WIDTH = 16;
	output reg [WIDTH-1:0] out;
	input  clk, reset, en;
	
	always @(posedge clk or negedge reset) begin
		if(~reset)
			out <= {WIDTH{1'b0}};
		else if(en)
			out <= out + { {(WIDTH-1){1'b0}}, {1'b1}};
	end
endmodule

module watch1to9(out, clock, globalReset);
	output [3:0] out;
	input  globalReset, clock;
	
	wire localReset;
	wire CLK_SEC;
	wire counterReset = globalReset & localReset;
	
	syncCounter #(4) SC0(out, CLK_SEC, counterReset, 1'b1);
	downClocker DC0(CLK_SEC, clock, globalReset, 1'b1);
	
	assign localReset = ~(out[3]&out[1]);
endmodule
			
module main(HEX3, HEX2, HEX1, HEX0, KEY, CLOCK_50);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [3:3] KEY;
	input  CLOCK_50;
	
	wire   [3:0] out;
	assign {HEX3, HEX2, HEX1} = {21{1'b1}};
	
	hexToSevSeg DEC0(HEX0, out);
	watch1to9   SEC0(out, CLOCK_50, KEY);
endmodule 

module tb;
	reg	CLOCK_50, KEY, SW;
	integer i;
	wire CLK_SEC;
	wire [25:0] out;
	downClocker DC0(CLK_SEC, out, CLOCK_50, KEY, SW);
	
	initial begin
		$monitor("%b %d %b", CLK_SEC, out, CLOCK_50);
		#0 SW = 1; KEY = 0; CLOCK_50 = 0;
		#1 SW = 1; KEY = 1; CLOCK_50 = 0;
		for(i = 0; i < 100000; i=i+1)
			#1 CLOCK_50 = ~CLOCK_50;
	end
endmodule