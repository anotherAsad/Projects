module vga(VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, pixR, pixG, pixB, clk, reset);
	output [3:0] VGA_R, VGA_G, VGA_B;
	output VGA_HS, VGA_VS;
	input  [3:0] pixR, pixG, pixB;
	input  clk, reset;

	reg  [11:0] hCount;
	reg  [10:0] vCount;
	reg  hdisp, hsync, vdisp, vsync;
	
	wire clrEn = vdisp & hdisp;

	assign VGA_HS = hsync;
	assign VGA_VS = vsync;
	assign VGA_R  = clrEn ? pixR :4'd0;
	assign VGA_G  = clrEn ? pixG :4'd0;
	assign VGA_B  = clrEn ? pixB :4'd0;

	// Counter Control
	always @(posedge clk or negedge reset) begin
		if(~reset)
			{hCount, vCount} <= 23'd0;
		else if(hCount == 12'd1039)
			{hCount, vCount} <= {12'd0, vCount+11'd1};
		else if(vCount == 11'd665)
			{hCount, vCount} <= 23'd0;
		else
			hCount <= hCount + 12'd1;
	end

	// Horizontal Control
	always @(posedge clk or negedge reset) begin
		if(~reset)
			{hdisp, hsync} = 2'b10;
		else case(hCount)			// Important Struct. default values are registered.
			12'd0000: {hdisp, hsync} = 2'b10;
			12'd0800: {hdisp, hsync} = 2'b00;
			12'd0856: {hdisp, hsync} = 2'b01;
			12'd0976: {hdisp, hsync} = 2'b00;
		endcase
	end

	// Vertical Control
	always @(posedge clk or negedge reset) begin
		if(~reset)
			{vdisp, vsync} = 2'b10;
		else case(vCount)			// Important Struct. default values are registered.
			11'd000: {vdisp, vsync} = 2'b10;
			11'd600: {vdisp, vsync} = 2'b00;
			11'd637: {vdisp, vsync} = 2'b01;
			11'd643: {vdisp, vsync} = 2'b00;
		endcase
	end
endmodule

module main(VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, SW, KEY, CLOCK_50);
	output [3:0] VGA_R, VGA_G, VGA_B;
	output VGA_HS, VGA_VS;
	input  [2:0] SW;
	input  [3:3] KEY;
	input  CLOCK_50;

	vga VGA(VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, {4{SW[2]}}, {4{SW[1]}}, {4{SW[0]}}, CLOCK_50, KEY);
endmodule
