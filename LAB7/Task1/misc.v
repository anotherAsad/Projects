module downClocker(pulse, limit, en, clk, reset);
	output reg pulse;
	input  clk, reset, en;
	input [25:0] limit;
	reg   [25:0] out;
	// 26'd24999999 for 1 sec
	always @(posedge clk or negedge reset) begin
		if(~reset) begin
			out <= 26'd0;
			pulse <= 1'b0;
		end
		else if(en) begin
			out <= out + 26'd1;					// Combinational action 1
			if(out == limit) begin				// Combinational action 2
				pulse <= ~pulse;
				out <= 26'd0;
			end
		end
	end
endmodule
