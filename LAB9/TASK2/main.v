module controlUnit(
	output reg [1:0] count,
	output reg  [9:0] muxOutLine,
	output reg  [9:0] regEnLine,
	output reg  IRin, addSub, done,
	input  wire [08:0] IR,
	input  wire run, reset, clk
);
	
	// Counter Control
	always @(posedge clk or negedge reset) begin
		if(~reset)
			count <= 2'b0;
		else if(done)				//	These Two Lines can be ommitted if you
			count <= 2'b0;			// want each instrunction to take 4 clock cycles.
		else if(run | count != 0)				// Run required for only one clk cycle
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
				if(IR[8:7] == 2'b01)begin	// Either Add or Subtract
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
				if(IR[8:7] == 2'b01)begin				// Either Add or Subtract
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
			for(i=0; i<8; i=i+1)
				R[i] <= 16'd0;
		else for(i=0; i<8; i=i+1) begin
			if(RxEn[i])
				R[i] <= bus;
		end
	end
	// Mux Logic
	always @(*) begin
		integer i;
		bus = 0;
		if(GSel)
			bus = G;
		else if(DinSel)
			bus = Din;
		else for(i=0; i<8; i=i+1)
			if(RxSel[i])
				bus = R[i];
	end
endmodule

module main(
	output wire [01:0] count,
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
		count,
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

module mains(
	output [6:0] HEX3, HEX2, HEX1, HEX0,
	output [0:0] LEDR,
	output [1:0] LEDG,
	input  [0:0] SW,
	input  [3:1] KEY
);
	wire [15:0] Din, bus;
	reg  [04:0] count;
	
	wire pclk  = ~KEY[3];
	wire mclk  = ~KEY[2];
	wire reset =  KEY[1];
	// Counter Logic
	always @(posedge mclk or negedge reset) begin
		if(~reset)
			count <= 5'd0;
		else
			count <= count + 5'd1;
	end

	ROM ROM_inst (
		.address(count),
		.clock(mclk),
		.data(16'd0),
		.wren(1'd0),
		.q(Din)
	);
	
	proc P0(
		.count(LEDG),
		.bus(bus),
		.done(LEDR),
		.Din(Din),
		.run(SW),
		.reset(reset),
		.clk(pclk) 
	);
	
	// Bus to Seven Seg Logic
	hexToSevSeg DEC0(HEX0, bus[03:00]);
	hexToSevSeg DEC1(HEX1, bus[07:04]);
	hexToSevSeg DEC2(HEX2, bus[11:08]);
	hexToSevSeg DEC3(HEX3, bus[15:12]);
endmodule
