module decoder(DISP, C);
	output [6:0] DISP;
	input  [2:0] C;
	wire   [6:0] charCode;
	wire   [6:0] xS = {7{C[2]}};
	
	assign charCode[0] = ~C[0];
	assign charCode[1] = C[1] ^ C[0];
	assign charCode[2] = C[1] ^ C[0];		// Try assign DISP[2]=DISP[1]
	assign charCode[3] = ~C[1] & ~C[0];
	assign charCode[4] = 1'b0;
	assign charCode[5] = 1'b0;
	assign charCode[6] = C[1];
	
	assign DISP = (~xS & charCode) | xS;
endmodule

module downClocker(pulse, clk, reset, en);
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

module rotReg(out, pIn, reset, load, clk);
	parameter WIDTH = 3;
	parameter DEPTH = 8;
		
	output reg [WIDTH*DEPTH-1:0] out;
	input  [WIDTH*DEPTH-1:0] pIn;
	input  clk, load, reset;
	
	integer i;
	always @(posedge clk or negedge reset or posedge load) begin
		if(~reset)
			out <= {WIDTH*DEPTH{1'b0}};
		else if(load)
			out <= pIn;
		else begin
			//Saad: out <= {{out[WIDTH*(DEPTH-1)-1:0]}, {out[WIDTH*DEPTH-1:WIDTH*(DEPTH-1)]}};
			out[WIDTH-1 -: WIDTH] <= out[WIDTH*DEPTH-1 -: WIDTH];
			for(i=2; i <= DEPTH; i = i+1)
				out[(WIDTH*i -1) -: WIDTH] <= out[(WIDTH*(i-1)-1) -: WIDTH];
		end
	end
endmodule

module main(HEX3, HEX2, HEX1, HEX0, CLOCK_50, KEY, SW);
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	input  [0:0] SW;
	input  [3:2] KEY;
	input  CLOCK_50;
	
	wire [23:0] out;
	wire [23:0] pIn = {3'b000, 3'b001, 3'b010, 3'b010, 3'b011, 3'b100, 3'b100, 3'b100};
	wire clk;
	
	decoder D0(HEX0, out[02:0]);
	decoder D1(HEX1, out[05:3]);
	decoder D2(HEX2, out[08:6]);
	decoder D3(HEX3, out[11:9]);
	
	downClocker DC0(clk, CLOCK_50, KEY[3], SW);
	rotReg      RR0(out, pIn, KEY[3], ~KEY[2], clk);
endmodule 
// KEY 3 is reset. KEY 2 is parallel load.