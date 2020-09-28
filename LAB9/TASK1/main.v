module controlUnit(
	output reg  [9:0] muxOutLine,
	output reg  [9:0] regEnLine,
	output reg  IRin, addSub, done,
	input  wire [08:0] IR,
	input  wire run, reset, clk
);
	reg [1:0] count;
	
	// Counter Control
	always @(posedge clk or negedge reset) begin
		if(~reset)
			count <= 2'b0;
		else if(run | count != 0)				// Run required for only one clk cycle.
			count <= count + 2'b1;
	end
	
	// Control Unit (Combinational Main part)
	always @(*) begin
		case (count)
			// Time Step 0
			2'b00: begin	//Update IR
				{muxOutLine, regEnLine} = 20'b0;
				{IRin, addSub, done} = 3'b100;
			end
			// Time Step 1
			2'b01:
			case(IR[8:6])
				3'b000: begin		// mv handle
					muxOutLine = 1'b1 << IR[2:0];		// Source
					regEnLine  = 1'b1 << IR[5:3];		// Destination
					{IRin, addSub, done} = {2'b0, 1'b1};
				end
				3'b001: begin			// mvi handle
					muxOutLine = 1'b1 << 9;				// Enable Din for mux select
					regEnLine  = 1'b1 << IR[5:3];		// Destination
					{IRin, addSub, done} = {2'b0, 1'b1};
				end
				3'b010, 3'b011: begin// add/Sub Handle
					muxOutLine = 1'b1 << IR[5:3];		// Source
					regEnLine  = 1'b1 << 8;				// Destination (A on loc8)
					{IRin, addSub, done} = 3'b0;
				end
				default: begin
					muxOutLine = 10'b0;
					regEnLine  = 10'b0;
					{IRin, addSub, done} = 3'b0;
				end
			endcase
			// Time Step 2
			2'b10:
				if(IR[8:7] == 2'b01)begin
					muxOutLine = 1'b1 << IR[2:0];
					regEnLine  = 1'b1 << 9;			// Destination (Gin Enable on Loc9)
					addSub = IR[6];					// 0 for Add. 1 for Sub
					{IRin, done} = 2'b0;
				end
				else begin		// This is combinational logic. Heed the else's to avoid latches.
					muxOutLine = 10'b0;
					regEnLine  = 10'b0;
					{IRin, addSub, done} = 3'b0;
				end
			// Time Step 3
			2'b11:
				if(IR[8:7] == 2'b01)begin
					muxOutLine = 1'b1 << 8;				// Gout enable
					regEnLine  = 1'b1 << IR[5:3];		// Rx in.
					{IRin, addSub, done} = 3'b1;		// Send Done signal.
				end
				else begin		// This is combinational logic. Heed the else's to avoid latches.
					muxOutLine = 10'b0;
					regEnLine  = 10'b0;
					{IRin, addSub, done} = 3'b0;
				end
		endcase
	end
endmodule

module regBank(
	output reg  [15:0] bus,
	input  wire [15:0] G, Din,
	input  wire [07:0] RxEn, RxSel,
	input  wire GSel, DinSel,
	input  wire reset, clk
);
	integer i;
	reg [15:0] R [7:0];
	// Register Logic
	always @(posedge clk or negedge reset) begin
		if(~reset)
			for(i=0; i<7; i=i+1)
				R[i] <= 16'd0;
		else for(i=0; i<7; i=i+1) begin
			if(RxEn[i])
				R[i] <= bus;
		end
	end
	// Mux Logic
	always @(*) begin
		integer i;
		bus = 16'd0;
		if(GSel)
			bus = G;
		else if(DinSel)
			bus = Din;
		else for(i=0; i<7; i=i+1)
			if(RxSel[i])
				bus = R[i];
	end
endmodule

module main(
	output wire [15:0] bus,
	output wire done,
	input  wire [15:0] Din,
	input  wire run, reset, clk 
);
	wire [9:0] muxOutLine, regEnLine;
	wire IRin, addSub;
	reg  [8:0] IR;
	reg  [15:0] A, G;
	
	// Reg A, G handle
	always @(posedge clk or negedge reset) begin
		if(~reset)
			{A, G} <= 32'd0;
		else begin
			if(regEnLine[8])
				A <= bus;
			if(regEnLine[9])
				G <= addSub ? A-bus: A+bus;
		end
	end
	
	// Instrunction Register Handle
	always @(posedge clk or negedge reset) begin
		if(~reset)
			IR <= 9'd0;
		else if(IRin)
			IR <= Din[15:7];
	end
	
	controlUnit CU0(
		muxOutLine,
		regEnLine,
		IRin, addSub, done,
		IR,
		run, reset, clk
	);
	
	regBank RB0(
		bus,
		G, Din,
		regEnLine[7:0], muxOutLine[7:0],
		muxOutLine[8], muxOutLine[9],
		reset, clk
	);
endmodule
