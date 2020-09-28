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

module bcdToSevSeg(out, in);
	output [6:0] out;
	input  [3:0] in;
	
	wire A = in[3], B = in[2], C =in[1], D = in[0];
	
	assign out[0] = (~A&~C)&(B^D);
	assign out[1] = (~A&B)&(C^D);
	assign out[2] = (~A&~B&C&~D);
	assign out[3] = (~A&B&~(C^D))|(~A&~B&~C&D);
	assign out[4] = (A&D) | (~A&~B&D) | (~A&B&(~C|D));
	assign out[5] = (~A&~B)&(C|D);
	assign out[6] = (~A&~B&~C)|(~A&B&C&D);
endmodule

module fullAdder(s1, s0, A, B, C);
	output s1, s0;
	input  A, B, C;
	
	wire midSum = A ^ B;
	assign s0 = midSum ^ C;
	wire midCry2 = midSum & C;
	wire midCry1 = A & B;
	assign s1 = midCry1 | midCry2;
endmodule

module RCAdder(cO, out, A, B, cI);
	parameter WIDTH = 8;
	output cO;
	output [WIDTH-1:0] out;
	input  cI;
	input  [WIDTH-1:0] A, B;
	wire   [WIDTH:0] C;		// Intermediate carry line
	
	assign {C[0], cO} = {cI, C[WIDTH]};
		
	generate
		genvar i;
		for(i=0; i<WIDTH; i=i+1) begin: m
			fullAdder FA(C[i+1], out[i], A[i], B[i], C[i]);
		end
	endgenerate
endmodule

module multiplier(M, A, B);
	parameter WIDTH = 8;
	output [2*WIDTH-1:0] M;
	input  [WIDTH-1:0] A, B;

	wire   [WIDTH-1:0] andLine [WIDTH-1:0];
	wire   [WIDTH-1:0] sumLine [WIDTH-1:0];
	wire   [WIDTH-1:0] cO;
	
	assign sumLine[0] = andLine[0];
	assign cO[0] = 1'b0;
	
	generate
		genvar i;
		for(i=0; i<WIDTH; i=i+1) begin: m
			assign andLine[i] = A & {WIDTH{B[i]}};
			assign M[i] = sumLine[i][0];
		end
	endgenerate
	
	generate
		for(i=0; i<WIDTH-1; i=i+1) begin: n
			RCAdder #(WIDTH) RCA(cO[i+1], sumLine[i+1], {cO[i],sumLine[i][WIDTH-1:1]}, andLine[i+1], 1'b0);
		end
	endgenerate
	
	assign M[2*WIDTH-1: WIDTH] = {cO[WIDTH-1], sumLine[WIDTH-1][WIDTH-1:1]};
endmodule

module downClocker(pulse, limit, en, clk, reset);
	output reg pulse;
	input  clk, reset, en;
	input [26:0] limit;
	reg   [26:0] out;
	// 27'd24999999 for 1 sec
	always @(posedge clk or negedge reset) begin
		if(~reset) begin
			out <= 27'd0;
			pulse <= 1'b0;
		end
		else if(en) begin
			out <= out + 27'd1;					// Combinational action 1
			if(out == limit) begin				// Combinational action 2
				pulse <= ~pulse;
				out <= 27'd0;
			end
		end
	end
endmodule

module binToBCD16bit(bcd4, bcd3, bcd2, bcd1, bcd0, S);
	output [03:0] bcd4, bcd3, bcd2, bcd1, bcd0;
	input  [15:0] S;
	
	assign bcd0 = (S%16'd00010);
	assign bcd1 = (S/16'd00010)%16'd10;
	assign bcd2 = (S/16'd00100)%16'd10;
	assign bcd3 = (S/16'd01000)%16'd10;
	assign bcd4 = (S/16'd10000);
endmodule

module binToBCD8bit(bcd2, bcd1, bcd0, S);
	output [3:0] bcd2, bcd1, bcd0;
	input  [7:0] S;
	
	assign bcd0 = (S%8'd00010);
	assign bcd1 = (S/8'd00010)%8'd10;
	assign bcd2 = (S/8'd00100);
endmodule
