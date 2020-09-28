module vgaCounter(dispEn, hsync, vsync, hCount, vCount, clk, reset);
	output reg  hsync, vsync;
	output reg  [11:0] hCount;
	output reg  [10:0] vCount;
	
	input  clk, reset;
	reg  hdisp, vdisp;
	
	output dispEn = vdisp & hdisp;

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

// Done till now

module vram(
	output [03:0] channelR, channelG, channelB,
	input  [11:0] hCoordR, hCoordW,
	input  [10:0] vCoordR, vCoordW,
	input  [03:0] dataInR, dataInG, dataInB,
	input  wEn, dispEn, clk
);
	wire [03:0] qR, qG, qB;
	wire [12:0] rAddr = vCoordR[10:3] * 8'd100 + hCoordR[11:3];
	wire [12:0] wAddr = vCoordW[10:3] * 8'd100 + hCoordW[11:3];

	assign channelR = dispEn ? qR: 4'b0000;
	assign channelG = dispEn ? qG: 4'b0000;
	assign channelB = dispEn ? qB: 4'b0000;

	vram_r vramR(clk, dataInR, rAddr, wAddr, wEn, qR);
	vram_g vramG(clk, dataInG, rAddr, wAddr, wEn, qG);
	vram_b vramB(clk, dataInB, rAddr, wAddr, wEn, qB);
endmodule

module main(VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, SW, KEY, CLOCK_50);
	output [3:0] VGA_R, VGA_G, VGA_B;
	output VGA_HS, VGA_VS;
	input  [0:0] SW;
	input  [3:3] KEY;
	input  CLOCK_50;

	wire   dispEn;
	wire   [11:0] hCount;
	wire   [10:0] vCount;
	vgaCounter VCNTR(dispEn, VGA_HS, VGA_VS, hCount, vCount, CLOCK_50, KEY);

	vram vram_inst(
		VGA_R, VGA_G, VGA_B,
		hCount, {12{SW}},
		vCount, {11{SW}},
		{4{SW}}, {4{SW}}, {4{SW}},
		SW, dispEn, CLOCK_50
	);
endmodule
