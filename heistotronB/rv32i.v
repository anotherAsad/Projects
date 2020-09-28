module fetchStage #(parameter coreNum=0)(	// 208 MHz with 256-word instrmem
	output reg  [07:0] pcNextPL, pcPL,
	output reg  [31:0] instrPL,
	input  wire [07:0] ext0,
	input  wire sig0, enable, clk, reset, clearPL
);
	reg  [07:0] pc;
	wire [31:0] instr;
	reg  [31:0] JBext, immJ, immB;
	reg  isJB;
	// PC_IN Mux Mesh.
	wire [07:0] pcInSel = sig0 ? ext0 : pcNext;		// Mux Feeding into PC
	wire [07:0] pcNext  = jIncSel + pc;			 	// adderOutput
	wire [07:0] jIncSel = isJB ? JBext[7:0] : 8'b1; // Mux feeding into adder
	// PC handle
	always @(posedge clk or negedge reset) begin
		if(~reset)
			pc <= 8'b0;
		else if(enable)
			pc <= pcInSel;
	end
	// IMEM handle
	generate
		if(coreNum == 0) begin: m0
			insMem0 IMEM(instr, pc);
		end
		else begin: m1
			insMem1 IMEM(instr, pc);
		end
	endgenerate
	// JB extender handle
	always @(*) begin
		isJB <= instr[6:4]==5'b110 & instr[3]==instr[2] ? 1'b1 : 1'b0;
		immJ <= {{12{instr[31]}}, instr[19:12] ,instr[20] ,instr[30:21] ,1'b0};
		immB <= {{20{instr[31]}}, instr[07], instr[30:25], instr[11:08], 1'b0};
		case(instr[2])
			1'b0: JBext <= {{2{immB[31]}}, immB[31:2]};		// B-type handle
			1'b1: JBext <= {{2{immJ[31]}}, immJ[31:2]};		// J-type handle
		endcase
	end
	// Pipeline Handle
	always @(posedge clk or negedge reset or posedge clearPL) begin
		if(~reset|clearPL)
			{pcPL, pcNextPL, instrPL} <= 48'd0;
		else if(enable)	
			{pcPL, pcNextPL, instrPL} <= {pc, pcNext, instr};
	end
endmodule

module decodeStage(	// 184 MHz fmax. RegBank not inferred.
	output reg  [07:0] pcNextPL, pcPL,
	output reg  [31:0] dataApL, dataBpL, immedPL,
	output reg  [00:0] stallLow, funct7bitPL,
	output reg  [02:0] funct3PL,
	input  wire [07:0] pcNext, pc,
	input  wire [31:0] dataDpc, dataDalu, instr,
	// Control Signals
	input  wire [01:0] immedSel,
	input  wire dataDsel, enable, clk, reset, clearPL
);
	reg  [04:0] addrD0, addrD1, addrD2;
	reg  [00:0] wren0, wren1, wren2;
	wire [31:0] dataA, dataB, dataD, immed;
	reg  stallConditionA, stallConditionB;
	
	// DataD input MUX
	assign dataD = dataDsel ? dataDpc : dataDalu;
	// RegBank Handle
	regFile RegBank(
		.dataA(dataA), .dataB(dataB),
		.dataD(dataD), .addrA(instr[19:15]),
		.addrB(instr[24:20]), .addrD(addrD2),
		.wren(wren2), .clk(clk)
	);
	// immedExtend Handle
	immedExtender immedExtender0(					// I, S, U, B/J
		.immedOut(immed),
		.immedField(instr[31:7]),
		.sel(immedSel)
	);
	// addrD Clear and Input handle
	always @(posedge clk or negedge reset or posedge clearPL) begin
		if(~reset|clearPL)
			{addrD0, wren0} <= 6'b0;
		else if(enable)
			{addrD0, wren0} <= {instr[11:7] & {5{stallLow}}, instr[5:2]!=4'b1000 & stallLow & instr[0]};
	end
	// addrD shift handle
	always @(posedge clk or negedge reset) begin
		if(~reset)
			{addrD1, addrD2, wren1, wren2} <= 12'b0;
		else if(enable) begin
			{addrD2, addrD1} <= {addrD1, addrD0};
			{wren2, wren1} <= {wren1, wren0};
		end
	end
	// Stall Logic Handle. Is combinational.
	always @(*) begin
		stallConditionA <= (instr[19:15]==addrD0 | instr[19:15]==addrD1 | instr[19:15]==addrD2) & instr[19:15]!=5'd0;
		stallConditionB <= (instr[24:20]==addrD0 | instr[24:20]==addrD1 | instr[24:20]==addrD2) & instr[24:20]!=5'd0;
		// Stall B for R,S,B type only. Do not stall A if AUIPC, LUI or JAL
		if(stallConditionA & ~(instr[2] & (instr[4]^instr[3])) | (stallConditionB & instr[5]==1'b1 & instr[3:2]==2'b00))
			stallLow <= 1'b0;
		else
			stallLow <= 1'b1;
	end
	// PipeLine Handle
	always @(posedge clk or negedge reset or posedge clearPL) begin
		if(~reset|clearPL)
			{dataApL, dataBpL, immedPL, pcNextPL, pcPL, funct3PL, funct7bitPL} <= 116'd0;
		else if(enable) begin
			{dataApL, dataBpL, immedPL, pcNextPL, pcPL} <= {dataA, dataB, immed, pcNext, pc};
			{funct3PL, funct7bitPL} <= {instr[14:12], instr[30]};
		end
	end
endmodule

module exeStage(
	output reg  [07:0] pcNextPL,
	output reg  [31:0] aluOutPL, dataBpL,
	output reg  [00:0] sig0PL,
	output reg  [02:0] funct3PL,
	input  wire [07:0] pc, pcNext,
	input  wire [31:0] dataA, dataB, immed,
	input  wire [02:0] funct3,
	input  wire [00:0] funct7bit,
	// Control Signals
	input  wire [00:0] alu1InSel, alu2InSel,
	input  wire [00:0] isItype, isRtype, isBranch,
	input  wire [00:0] enable, clk, reset
);
	wire [31:0] alu1In, alu2In, aluOut;
	wire branchValid, sig0;
	// Pre-ALU muxes
	assign alu1In = alu1InSel ? {24'b0, pc} : dataA;
	assign alu2In = alu2InSel ? immed: dataB;
	// ALU handle
	alu ALU0(
		.aluOut(aluOut),
		.inpA(alu1In), .inpB(alu2In),
		.funct3(funct3),
		.funct7bit(funct7bit),
		.isItype(isItype),
		.isRtype(isRtype)
	);
	// Comparator Handle
	cmpUnit CMP0(
		.jmpStat(branchValid),
		.dataA(dataA),
		.dataB(dataB),
		.funct3(funct3),
		.branch(isBranch)
	);
	// assign sig0 a high value if only the branch taken was not valid. High results in PC override.
	assign sig0 = isBranch & ~branchValid;
	// Pipeline Handle
	always @(posedge clk or negedge reset) begin
		if(~reset)
			{pcNextPL, aluOutPL, dataBpL, sig0PL, funct3PL} <= 76'd0;
		else if(enable)
			{pcNextPL, aluOutPL, dataBpL, sig0PL, funct3PL} <= {pcNext, aluOut, dataB, sig0, funct3};
	end
endmodule

module memStage(
	output reg  [07:0] pcNextPL,
	output reg  [31:0] dataDpL,
	input  wire [07:0] pcNext,
	input  wire [31:0] aluOutInt, dataBInt,
	input  wire [02:0] funct3Int,
	// Coherency Inputs
	input  wire [31:0] aluOutExt, dataBExt,
	input  wire [02:0] funct3Ext,
	// Control Signals
	input  wire [00:0] wrenInt, wrenExt, isLoad,
	input  wire [00:0] enable, clk, reset
);
	wire [31:0] dmemOut, dataD;
	// Coherency Muxes. Enable high means no external stall from coherency controller override.
	wire [31:0] aluOut = enable ? aluOutInt : aluOutExt;
	wire [31:0] dataB  = enable ? dataBInt  : dataBExt;
	wire [02:0] funct3 = enable ? funct3Int : funct3Ext;
	wire [00:0] wren   = enable ? wrenInt   : wrenExt;
	// DMEM handle
	dataMem DMEM(
		.dmemOut(dmemOut),
		.dIn(dataB),
		.addrIn(aluOut[2:0]),
		.funct3(funct3),
		.wren(wren), .clk(clk)
	);
	// ALU/DMEM out MUX
	assign dataD = isLoad ? dmemOut : aluOut;
	// Pipeline Handle
	always @(posedge clk or negedge reset) begin
		if(~reset)
			{pcNextPL, dataDpL} <= 40'd0;
		else if(enable)
			{pcNextPL, dataDpL} <= {pcNext, dataD};
	end
endmodule

module rv32i #(parameter coreNum=0)(
	output [31:0] dataDWb,
	// DMEM signal exposure for cache coherency
	output [31:0] aluOutMem, dataBMem,
	output [02:0] funct3Mem,
	output [00:0] dmemWren,
	// DMEM signal inlet for cache coherency. 'C' stands for Coherency Controller.
	input  [31:0] aluOutMemC, dataBMemC,
	input  [02:0] funct3MemC,
	input  [00:0] dmemWrenC,
	// Input Signals
	input  [00:0] extStall, clk, reset
);
	wire [07:0] pcNextDec, pcNextExe, pcNextMem, pcNextWb;
	wire [07:0] pcDec, pcExe;
	wire [31:0] instr, dataAExe, dataBExe, immedExe;
	wire [00:0] sig0, stallLow, funct7bitExe;
	wire [02:0] funct3Exe;
	// Control Signals
	wire [01:0] immedSel;
	wire [00:0] isLoad, isItype, isRtype, isBranch, dataDsel, alu1InSel, alu2InSel;
	
	fetchStage #(coreNum) FETCH(
		.pcNextPL(pcNextDec), .pcPL(pcDec),
		.instrPL(instr),
		.ext0(aluOutMem[7:0]),
		.sig0(sig0), .enable(stallLow&~extStall), .clk(clk),
		.reset(reset), .clearPL(sig0)
	);
	
	decodeStage DECODE(
		.pcNextPL(pcNextExe), .pcPL(pcExe),
		.dataApL(dataAExe), .dataBpL(dataBExe),
		.immedPL(immedExe), .stallLow(stallLow),
		.funct3PL(funct3Exe), .funct7bitPL(funct7bitExe),
		.pcNext(pcNextDec), .pc(pcDec),
		.dataDpc({24'b0, pcNextWb}), .dataDalu(dataDWb), .instr(instr),
		// Control Signals
		.immedSel(immedSel), .dataDsel(dataDsel),
		.enable(~extStall), .clk(clk), .reset(reset), .clearPL(sig0)
	);
	
	exeStage EXE(
		.pcNextPL(pcNextMem),
		.aluOutPL(aluOutMem), .dataBpL(dataBMem),
		.sig0PL(sig0), .funct3PL(funct3Mem),
		.pc(pcExe), .pcNext(pcNextExe),
		.dataA(dataAExe), .dataB(dataBExe), .immed(immedExe),
		.funct3(funct3Exe), .funct7bit(funct7bitExe),
		// Control Signals
		.alu1InSel(alu1InSel), .alu2InSel(alu2InSel),
		.isItype(isItype), .isRtype(isRtype), .isBranch(isBranch),
		.enable(~extStall), .clk(clk), .reset(reset)
	);
	
	memStage MEM(
		.pcNextPL(pcNextWb),
		.dataDpL(dataDWb),
		.pcNext(pcNextMem),
		// Internal Inputs
		.aluOutInt(aluOutMem), .dataBInt(dataBMem),
		.funct3Int(funct3Mem),
		// Coherency Inputs
		.aluOutExt(aluOutMemC), .dataBExt(dataBMemC),
		.funct3Ext(funct3MemC),
		// Control Signals
		.wrenInt(dmemWren), .wrenExt(dmemWrenC), .isLoad(isLoad),
		.enable(~extStall), .clk(clk), .reset(reset)
	);
	
	controlUnit CU(
		.dmemWren(dmemWren), .alu1InSel(alu1InSel), .alu2InSel(alu2InSel),
		.isItype(isItype), .isRtype(isRtype), .isLoad(isLoad), .isJALR(dataDsel),
		.isBranch(isBranch), .immedSel(immedSel), .opcode(instr[6:0]),
		.clk(clk), .reset(reset), .clearPL(sig0), .enable(~extStall)
	);
endmodule