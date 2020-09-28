module controlUnit(
	output wire [9:0] muxSelect,
	output wire [9:0] regSelect,
	output wire INSin, Done, Wren,
	output wire DataIn, IncrPC,
	output wire AddrIn, AddSub,
	input  wire [8:0] IR,
	input  wire busNotZero,
	input  wire run, reset, clk
);
	reg  stall;
	reg  [9:0] muxOutLine, regEnLine;
	reg  IRin, done, wren, dataIn, incrPC, addrEn;
	
	// Stall handle
	always @(posedge clk or negedge reset) begin
		if(~reset)
			stall <= 1'b0;
		else
			stall <= regEnLine[7];
	end
	
	// Mask Signals at stall
	assign muxSelect = muxOutLine & {10{~stall}};
	assign regSelect = regEnLine  & {10{~stall}};
	assign AddSub = (IR[8:7] == 2'b01) & IR[6] & ~stall;
	assign AddrIn = (addrEn | regEnLine[7]) & ~stall;
	assign {INSin, Done, Wren, DataIn, IncrPC} = {IRin, done, wren, dataIn, incrPC} & {5{~stall}};
	
	// Micro-op counter
	reg [1:0] uop;
	always @(posedge clk or negedge reset) begin
		if(~reset)
			uop <= 0;
		else if(run)
			uop <= (uop + {1'b0, ~stall}) & {2{~Done}};
	end
	
	// Micro-coded instructions
	always @(*) begin
		case(IR[8:6])
		3'b000:						// mv Rx, Ry									
			case(uop)
			2'b00: begin							// RxIn, RyOut, incrPC
				regEnLine  = 1'b1 << IR[5:3];
				muxOutLine = 1'b1 << IR[2:0];
				{IRin, addrEn, done} = 3'h0;
				{wren, dataIn, incrPC} = 3'h1;
			end
			default: begin							// IRin, R7out, AddrEn, done
				muxOutLine = 1'b1 << 7;
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'h7;
				{wren, dataIn, incrPC} = 3'h0;
			end
			endcase
		// MOV INSTR DONE
		3'b001:						// mvi Rx, #IMMED
			case(uop)
			2'b00: begin							// incrPC
				muxOutLine = 10'b0;
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'b000;
				{wren, dataIn, incrPC} = 3'h1;
			end
			2'b01: begin							// R7out, AddrIn
				muxOutLine = 1'b1 << 7;
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'b010;
				{wren, dataIn, incrPC} = 3'h0;
			end
			2'b10: begin							// DinOUt, RxIn, incrPC
				muxOutLine = 1'b1 << 8;
				regEnLine  = 1'b1 << IR[5:3];
				{IRin, addrEn, done} = 3'b000;
				{wren, dataIn, incrPC} = 3'h1;
			end
			default: begin							// IRin, R7Out, AddrEn, done
				muxOutLine = 1'b1 << 7;
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'h7;
				{wren, dataIn, incrPC} = 3'h0;
			end
			endcase
		// MVI INSTR DONE
		3'b010, 3'b011:						// add/sub rx, ry
			case(uop)
			2'b00: begin							// RyOut, Ain
				muxOutLine = 1'b1 << IR[2:0];
				regEnLine  = 1'b1 << 8;			// write to A
				{IRin, addrEn, done} = 3'h0;
				{wren, dataIn, incrPC} = 3'h0;
			end
			2'b01: begin							// RxOut, Gin, Add
				muxOutLine = 1'b1 << IR[5:3];
				regEnLine  = 1'b1 << 9;			// write to G
				{IRin, addrEn, done} = 3'h0;
				{wren, dataIn, incrPC} = 3'h0;
			end
			2'b10: begin							// Gout, RxIn, incrPC
				muxOutLine = 1'b1 << 9;			// Gout
				regEnLine  = 1'b1 << IR[5:3];	// write to Rx
				{IRin, addrEn, done} = 3'h0;
				{wren, dataIn, incrPC} = 3'h1;
			end
			default: begin							// IRin, R7out, AddrEn, done
				muxOutLine = 1'b1 << 7;
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'h7;
				{wren, dataIn, incrPC} = 3'h0;
			end
			endcase
			// ADD/SUB INSTR DONE
		3'b100:						// ld Rx, Ry
			case(uop)
			2'b00: begin							// RyOut, AddrEn
				muxOutLine = 1'b1 << IR[2:0];
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'b010;
				{wren, dataIn, incrPC} = 3'h0;
			end
			2'b01: begin							// R7Out, AddrEn
				muxOutLine = 1'b1 << 7;
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'b010;
				{wren, dataIn, incrPC} = 3'h0;
			end
			2'b10: begin							// DinOut, RxIn, incrPC
				muxOutLine = 1'b1 << 8;
				regEnLine  = 1'b1 << IR[5:3];
				{IRin, addrEn, done} = 3'b000;
				{wren, dataIn, incrPC} = 3'b001;
			end
			default: begin							// IRin, R7out, AddrEn, done
				muxOutLine = 1'b1 << 7;
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'h7;
				{wren, dataIn, incrPC} = 3'h0;
			end
			endcase
			// LD INSTR DONE
		3'b101:						// st rx, ry
			case(uop)
			2'b00: begin							// DataIn, RxOut
				muxOutLine = 1'b1 <<< IR[5:3];
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'h0;
				{wren, dataIn, incrPC} = 3'b010;
			end
			2'b01: begin							// AddrEn, RyOut, incrPC, wren
				muxOutLine = 1'b1 << IR[2:0];
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'b010;
				{wren, dataIn, incrPC} = 3'b101;
			end
			default: begin							// AddrEn, R7out, IRin, done
				muxOutLine = 1'b1 << 7;
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'h7;
				{wren, dataIn, incrPC} = 3'h0;
			end
			endcase
			// ST INSTR DONE
		3'b110:						// mvnz rx, ry									
			case(uop)
			2'b00: begin							// RxIn, RyOut, incrPC
				regEnLine  = busNotZero << IR[5:3];
				muxOutLine = 1'b1 << IR[2:0];
				{IRin, addrEn, done} = 3'h0;
				{wren, dataIn, incrPC} = 3'h1;
			end
			default: begin							// IRin, R7out, AddrEn, done
				muxOutLine = 1'b1 << 7;
				regEnLine  = 10'b0;
				{IRin, addrEn, done} = 3'h7;
				{wren, dataIn, incrPC} = 3'h0;
			end
			endcase
		default: begin							// IRin, R7out, AddrEn, done
			muxOutLine = 1'b1 << 7;
			regEnLine  = 1'b1 << 0;
			{IRin, addrEn, done} = 3'h7;
			{wren, dataIn, incrPC} = 3'h0;
		end
		endcase
	end
endmodule

module regBank(
	output reg  [15:0] bus,
	input  wire [15:0] G, Din,
	input  wire [07:0] RxEn, RxSel,
	input  wire GSel, DinSel, incrPC,
	input  wire reset, clk
);
	reg [15:0] R [7:0];

	// Register Logic
	always @(posedge clk or negedge reset) begin
		integer i;
		if(~reset)
			for(i=0; i<7; i=i+1)
				R[i] <= 16'd0;
		else for(i=0; i<7; i=i+1) begin
			if(RxEn[i])
				R[i] <= bus;
		end
	end
	// Counter Logic
	always @(posedge clk or negedge reset) begin
		if(~reset)
			R[7] <= 16'd0;
		else if(RxEn[7])		// Precedence given to write over increment. Crucial.
			R[7] <= bus;
		else if(incrPC)
			R[7] <= R[7] + 16'b1;
	end
	// Mux Logic
	always @(*) begin
		integer i;
		bus = 16'b0;
		if(GSel)
			bus = G;
		else if(DinSel)
			bus = Din;
		else for(i=0; i<8; i=i+1)
			if(RxSel[i])
				bus = R[i];
	end
endmodule

module core(
	output wire [15:0] bus,
	output reg  [15:0] ADDR, DOUT, 
	output reg  W,
	output wire done,
	input  wire [15:0] Din,
	input  wire run, reset, clk
);
	wire IRin, addSub, wren, dataIn, addrIn, incrPC;
	wire [9:0] muxOutLine, regEnLine;
	reg  [8:0] IR;
	reg  [15:0] A, G;
	
	wire busNotZero = |bus;
	// Reg A, G, ADDR, DOUT  handle
	always @(posedge clk or negedge reset) begin
		if(~reset)
			{A, G, ADDR, DOUT} <= 64'd0;
		else begin
			if(regEnLine[8])
				A <= bus;
			if(regEnLine[9])
				G <= addSub ? A-bus: A+bus;
			if(addrIn)
				ADDR <= bus;
			if(dataIn)
				DOUT <= bus;
			W <= wren;
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
		IRin, done, wren,
		dataIn, incrPC,
		addrIn, addSub,
		IR, busNotZero,
		run, reset, clk
	);
	
	regBank RB0(
		.bus(bus),
		.G(G), .Din(Din),
		.RxEn(regEnLine[7:0]),
		.RxSel(muxOutLine[7:0]),
		.GSel(muxOutLine[9]),
		.DinSel(muxOutLine[8]),
		.incrPC(incrPC),
		.reset(reset), .clk(clk)
	);
endmodule

// Quartus infers SYNCRAM
module RAM(
	output reg  [15:0] DOUT,
	input  wire [15:0] DIN,
	input  wire [07:0] ADDR,
	input  wire wren, reset, clk
);
	reg [15:0] MEM [255:0];
		
	initial begin
		integer i;
		for(i=0; i<256; i=i+1)
			MEM[i] = 0;
		MEM[00] = {3'b001, 3'b001, 3'b000, 7'd0};		// mvi	R1, #DEADh
		MEM[01] = 16'hDEAD;
		MEM[02] = {3'b001, 3'b010, 3'b001, 7'd0};		// mvi	R2, #6969h
		MEM[03] = 16'h6969;
		MEM[04] = {3'b010, 3'b001, 3'b010, 7'd0};		// add	R1, R2
		MEM[05] = {3'b011, 3'b001, 3'b001, 7'd0};		// sub	R1, R1
		MEM[06] = {3'b000, 3'b001, 3'b010, 7'd0};		// mv		R1, R2
		MEM[07] = {3'b001, 3'b000, 3'b000, 7'd0};		// mvi	R0, #1h
		MEM[08] = 16'h1;
		MEM[09] = {3'b100, 3'b001, 3'b000, 7'd0};		// ld		R1, R0
		MEM[10] = {3'b101, 3'b010, 3'b000, 7'd0};		// st		R2, R0
		MEM[11] = {3'b100, 3'b001, 3'b000, 7'd0};		// ld		R1, R0
		MEM[12] = {3'b110, 3'b001, 3'b000, 7'd0};		// mvnz 	R1, R0
		MEM[13] = {3'b011, 3'b000, 3'b000, 7'd0};		// sub	R0, R0
		MEM[14] = {3'b001, 3'b100, 3'b000, 7'd0};		// mvi	R4, #1h
		MEM[15] = 16'h1;
		MEM[16] = {3'b001, 3'b110, 3'b000, 7'd0};		// mvi	R6, #AAAAh
		MEM[17] = 16'hAAAA;
		MEM[18] = {3'b001, 3'b101, 3'b000, 7'd0};		// mvi	R5, #0100h
		MEM[19] = 16'h0100;
		MEM[20] = {3'b101, 3'b110, 3'b101, 7'd0};		// st		R6, R5
		MEM[21] = {3'b010, 3'b110, 3'b110, 7'd0};		// add	R6, R6
		MEM[22] = {3'b010, 3'b110, 3'b100, 7'd0};		// add	R6, R4
		MEM[23] = {3'b101, 3'b110, 3'b101, 7'd0};		// st		R6, R5
		MEM[24] = {3'b010, 3'b110, 3'b110, 7'd0};		// add	R6, R6
		// goto 20
		MEM[25] = {3'b001, 3'b111, 3'b000, 7'd0};		// mvi	R7, #14h
		MEM[26] = 16'h14;
	end
	
	always @(posedge clk or negedge reset) begin
		if(~reset)
			DOUT <= 16'd0;
		else begin
			DOUT <= MEM[ADDR];
			if(wren)
				MEM[ADDR] <= DIN;
		end
	end
endmodule

module LED_MM(
	output reg  [15:0] arrayLED,
	input  wire [15:0] inpLED,
	input  wire wren, clk, reset
	);
	
	always @(posedge clk or negedge reset) begin
		if(~reset)
			arrayLED <= 16'd0;
		else if(wren)
			arrayLED <= inpLED;
	end
endmodule

module main(
	output [6:0] HEX3, HEX2, HEX1, HEX0,
	output [7:0] LEDG,
	output [9:0] LEDR,
	input  [9:8] SW,
	input  [3:3] KEY,
	input	 [0:0] CLOCK_50
);
	// Wire-up
	wire W, done;
	wire run = 1'b1;
	wire clk;
	wire reset = KEY[3];
	wire [15:0] bus;
	wire [15:0] ADDR, DOUT, Din;
	
	wire [15:0] bin = SW[8] ? bus: ADDR;
	
	assign LEDG[6] = ADDR[8];
	assign LEDG[7] = done;
		
	core xCore(
		bus, ADDR, DOUT, 
		W, done,
		Din,
		run, reset, clk
	);
	
	RAM R0(Din, DOUT, ADDR[7:0], ~ADDR[8]&W, reset, clk);
	LED_MM LED_MM0({LEDG[5:0], LEDR}, DOUT, ADDR[8]&W , clk, reset);
	
	downClocker DC0(clk, 27'd1249999 << ({1'b0, SW[9]} << 1), 1'b1, CLOCK_50, reset);
	hexToSevSeg DEC0(HEX0, bin[03:00]);
	hexToSevSeg DEC1(HEX1, bin[07:04]);
	hexToSevSeg DEC2(HEX2, bin[11:08]);
	hexToSevSeg DEC3(HEX3, bin[15:12]);
endmodule
