module insPtr(						// 256 instructions in L1-INS cache 
	output reg  [07:0] addrOut,
	output wire [07:0] nextAddr,
	input  wire [07:0] addrIn,
	input  wire en, load, clk, reset
);
	assign nextAddr = addrOut+8'b1;
	always @(posedge clk or negedge reset) begin
		if(~reset)
			addrOut <= 7'b0;
		else if(en)
			addrOut <= load ? addrIn : nextAddr;
	end
endmodule

module insMem0(
	output reg  [31:0] insOut,
	input  wire [07:0] imem_addr
);
	reg [31:0] imem [0:256];
	// Read
	always @(*) begin
		insOut <= imem[imem_addr];
	end
	// Init
	initial begin
		// Table of 17
		imem[00] = 32'h01100093;
		imem[01] = 32'h00A00113;
		imem[02] = 32'h00100193;
		imem[03] = 32'h01108093;
		imem[04] = 32'h00118193;
		imem[05] = 32'hFE21CCE3;
		imem[06] = 32'h00102023;
		imem[07] = 32'h00402283;
		/*
		imem[00] = 32'h00D00093;		// addi x1, x0, 13
		imem[01] = 32'h00E00113;		// addi x2, x0, 14
		imem[02] = 32'h002081B3;		// add  x3, x1, x2
		imem[03] = 32'h0020A233;		// slt  x4, x1, x2
		imem[04] = 32'h00302023;		// sw   x3, 0(x0)
		imem[05] = 32'h00003283;		// lw   x5, 0(x0)
		imem[06] = 32'h005182B3;		// add  x5, x3, x5
		imem[07] = 32'h00000013;		// addi x0, x0, x0
		*/
	end
endmodule

module insMem1(
	output reg  [31:0] insOut,
	input  wire [07:0] imem_addr
);
	reg [31:0] imem [0:256];
	// Read
	always @(*) begin
		insOut <= imem[imem_addr];
	end
	// Init
	initial begin
		// Table of 13
		imem[00] = 32'h00D00093;
		imem[01] = 32'h00A00113;
		imem[02] = 32'h00100193;
		imem[03] = 32'h00D08093;
		imem[04] = 32'h00118193;
		imem[05] = 32'hFE21CCE3;
		imem[06] = 32'h00102223;
		imem[07] = 32'h00002283;
		/*
		imem[00] = 32'h00D00093;		// addi x1, x0, 13
		imem[01] = 32'h00E00113;		// addi x2, x0, 14
		imem[02] = 32'h002081B3;		// add  x3, x1, x2
		imem[03] = 32'h0020A233;		// slt  x4, x1, x2
		imem[04] = 32'h00302023;		// sw   x3, 0(x0)
		imem[05] = 32'h00003283;		// lw   x5, 0(x0)
		imem[06] = 32'h005182B3;		// add  x5, x3, x5
		imem[07] = 32'h00000013;		// addi x0, x0, x0
		*/
	end
endmodule

module regFile(
	output reg  [31:0] dataA, dataB,
	input  wire [31:0] dataD,
	input  wire [04:0] addrA, addrB, addrD,
	input  wire [00:0] wren, clk
);
	reg [31:0] registers [1:31];
	// Read
	always @(*) begin
		dataA <= addrA==5'b0 ? 32'b0 : registers[addrA];
		dataB <= addrB==5'b0 ? 32'b0 : registers[addrB];
	end
	// Write
	always @(posedge clk) begin
		if(wren && addrD!=5'b0)
			registers[addrD] <= dataD;
	end
endmodule

// Data memory is byte addressible but word-spaced.
module dataMem(					// 256 bytes of data
	output reg  [31:0] dmemOut,
	input  wire [31:0] dIn,
	input  wire [02:0] addrIn,
	input  wire [02:0] funct3,
	input  wire [00:0] wren, clk
);
	reg  [31:0] dmem [0:8];
	// read
	always @(*)
		dmemOut <= dmem[addrIn];
	// write
	always @(posedge clk)
		if(wren) dmem[addrIn] <= dIn;
endmodule
/*
module dataMem(					// 256 bytes of data
	output reg  [31:0] dmemOut,
	input  wire [31:0] dIn,
	input  wire [07:0] addrIn,
	input  wire [02:0] funct3,
	input  wire [00:0] wren, clk
);
	reg  [31:0] dOut;
	reg  [07:0] dmem [0:255];
	// read
	always @(*) begin
		dOut <= {dmem[addrIn+3], dmem[addrIn+2], dmem[addrIn+1], dmem[addrIn]};
	end
	// write
	always @(posedge clk) begin
		if(wren) case(funct3[1:0])
			2'b00: dmem[addrIn] <= dIn[7:0];
			2'b01: {dmem[addrIn+1], dmem[addrIn]} <= dIn[15:0];
			2'b10: {dmem[addrIn+3], dmem[addrIn+2], dmem[addrIn+1], dmem[addrIn]} <= dIn;
			2'b11: dmem[addrIn] <= dIn[7:0];
		endcase
	end
	
	// Load Type Handle
	always @(*) begin
		case(funct3)
			3'b000 : dmemOut <= {{24{dOut[07]}}, dOut[07:0]};
			3'b001 : dmemOut <= {{16{dOut[15]}}, dOut[15:0]};
			3'b010 : dmemOut <= dOut;
			3'b011 : dmemOut <= {24'b0, dOut[07:0]};
			3'b101 : dmemOut <= {16'b0, dOut[15:0]};
			default: dmemOut <= dOut;
		endcase
	end
endmodule
*/
module immedExtender(						// I, S, U, B/J
	output reg  [31:00] immedOut,
	input  wire [31:07] immedField,
	input  wire [01:00] sel
);
	wire [31:00] immI = {{21{immedField[31]}}, immedField[30:20]};
	wire [31:00] immS = {{21{immedField[31]}}, immedField[30:25], immedField[11:07]};
	wire [31:00] immU = {immedField[31:12], 12'b0};
	
	always @(*) begin
		case(sel)
			2'b00: immedOut <= immI;
			2'b01: immedOut <= immS;
			2'b10: immedOut <= immU;
			2'b11: immedOut <= 32'd1;
		endcase
	end
endmodule

module alu(
	output reg  [31:0] aluOut,
	input  wire [31:0] inpA, inpB,
	input  wire [02:0] funct3,
	input  wire funct7bit, isItype, isRtype
);
	wire isMathOp = isItype | isRtype;
	wire [2:0] opSel = isMathOp ? funct3 : 3'b0;
	always @(*) begin
		case(opSel)
			3'b000: aluOut <= funct7bit & isRtype ? inpA - inpB: inpA + inpB;							// ADD/SUB
			3'b001: aluOut <= inpA << inpB[4:0];														// SLL
			3'b010: aluOut <= {31'b0, $signed(inpA) < $signed(inpB)};									// SLT
			3'b011: aluOut <= {31'b0, inpA < inpB};														// SLTU
			3'b100: aluOut <= inpA ^ inpB;																// XOR
			3'b101: aluOut <= funct7bit & isMathOp ? $signed(inpA)>>>inpB[4:0]: inpA>>inpB[4:0];// SRL/SRA
			3'b110: aluOut <= inpA | inpB;																// OR
			3'b111: aluOut <= inpA & inpB;																// AND
		endcase
	end
endmodule

module cmpUnit(
	output wire jmpStat,
	input  wire [31:0] dataA, dataB,
	input  wire [02:0] funct3,
	input  wire branch
);
	reg  [2:0] cmpStatus;
	reg  jump;
	assign jmpStat = branch & jump;
	always @(*) begin
		cmpStatus[0] = ~|(dataA^dataB);						// BEQ
		cmpStatus[1] = $signed(dataA) < $signed(dataB);		// BLT
		cmpStatus[2] = dataA < dataB;						// BLTU
	end
	always @(*) begin
		case(funct3[2:1])
			2'b00: jump <= cmpStatus[0] ^ funct3[0];
			2'b01: jump <= 1'b0;
			2'b10: jump <= cmpStatus[1] ^ funct3[0];
			2'b11: jump <= cmpStatus[2] ^ funct3[0];
		endcase
	end
endmodule

// clearPL signal is used to clear for branch-miss.
// stallLow is used for register stalls. StallLow serves as enable. Not Needed.
module controlUnit(
	output reg  dmemWren, alu1InSel, alu2InSel,
	output reg  isItype, isRtype, isLoad, isJALR, isBranch,
	output wire [1:0] immedSel,//isub
	input  wire [6:0] opcode,
	input  wire [0:0] clk, reset, clearPL, enable
);
	wire alu1InSel_Dec, alu2InSel_Dec, isItype_Dec, isRtype_Dec, isBranch_Dec;
	wire dmemWren_Dec, isLoad_Dec, isJALR_Dec;
	// PipeLine Signals
	reg dmemWren_Exe, isLoad_Exe, isJALR_Exe, isJALR_Mem;
	// Decode Stage Signals
	assign immedSel[0] = opcode[5:4]==2'b10 & opcode[3:2]!=2'b01;		// 1 @ 11011, 11000, 01000
	assign immedSel[1] = (opcode[6]!=1'b0|opcode[3:2]!=2'b0) & opcode[6:2]!=5'b11001;
	//opcode[6:2]!=5'b00x00 & opcode[6:2]!=5'b11001; // 0 @ 00100, 00000, 11001, 01000
	// Exe Stage Signals
	assign alu1InSel_Dec = opcode[6:2]==5'b00101 | opcode[6:2]==5'b11011 | opcode[6:2]==5'b11000;
	assign alu2InSel_Dec = opcode[6:2]!=5'b01100;
	assign isItype_Dec   = opcode[6:2]==5'b00100;
	assign isRtype_Dec   = opcode[6:2]==5'b01100;
	assign isBranch_Dec  = opcode[6:2]==5'b11000;
	// Mem Stage Signals
	assign dmemWren_Dec  = opcode[6:4]==3'b010;
	assign isLoad_Dec    = (|opcode[6:2])==1'b0;
	// WriteBack Stage Signals
	assign isJALR_Dec    = opcode[6:2]==5'b11001;
	// 01101 : LUI			alu2InSel, immedSel=10
	// 00101 : AUIPC		alu1InSel, alu2InSel, immedSel=10
	// 11011 : JAL			alu1InSel, alu2InSel, immedSel=11
	// 11001 : JALR			alu2InSel, isJALR, immedSel=00
	// 11000 : BEQ			alu1InSel, alu2InSel, immedSel=11
	// 00000 : LW			alu2InSel ,isLoad, immedSel=00
	// 01000 : SW			dmemWren, alu2InSel, immedSel=01
	// 00100 : ADDI			alu2InSel, isItype, immedSel=00
	// 01100 : ADD			isRtype, immedSel=xx
	// PipeLine Handle: Exe
	always @(posedge clk or negedge reset or posedge clearPL) begin
		if(~reset|clearPL) begin
			{alu1InSel, alu2InSel, isItype, isRtype, isBranch} <= 5'b0;
			{dmemWren_Exe, isLoad_Exe, isJALR_Exe} <= 3'b0;
		end
		else if(enable) begin
			{alu1InSel, alu2InSel} <= {alu1InSel_Dec, alu2InSel_Dec};
			{isItype, isRtype, isBranch} <= {isItype_Dec, isRtype_Dec, isBranch_Dec};
			{dmemWren_Exe, isLoad_Exe, isJALR_Exe} <= {dmemWren_Dec, isLoad_Dec, isJALR_Dec};
		end
	end
	// PipeLine Handle: Mem
	always @(posedge clk or negedge reset) begin
		if(~reset)
			{dmemWren, isLoad, isJALR_Mem} <= 3'b0;
		else if(enable)
			{dmemWren, isLoad, isJALR_Mem} <= {dmemWren_Exe, isLoad_Exe, isJALR_Exe};
	end
	// PipeLine Handle: WB
	always @(posedge clk or negedge reset) begin
		if(~reset)
			isJALR <= 1'b0;
		else if(enable)
			isJALR <= isJALR_Mem;
	end
endmodule