`default_nettype none

module coherencyController(
	output reg  extStall,
	// Out Ports. Will serve as inputs to Ext ports of both processors.
	output reg  [31:0] addrOutC0, addrOutC1, dataOutC0, dataOutC1,
	output reg  [02:0] funct3OutC0, funct3OutC1,
	output reg  [00:0] wrenOutC0, wrenOutC1,
	// In Ports. Will collect Int Inputs from both processors.
	input  wire [31:0] addrInC0, addrInC1, dataInC0, dataInC1,
	input  wire [02:0] funct3InC0, funct3InC1,
	input  wire [00:0] wrenInC0, wrenInC1,
	// clk and co.
	input  wire [00:0] clk, reset
);
	// Stall Maker
	always @(posedge clk or negedge reset) begin
		if(~reset)
			extStall <= 1'b0;
		else
			extStall <=  (wrenInC0 | wrenInC1) & ~extStall;
	end
	// Signal Communication
	always @(posedge clk or negedge reset) begin
		if(~reset) begin
			{addrOutC0, addrOutC1, dataOutC0, dataOutC1} <= 128'd0;
			{funct3OutC0, funct3OutC1} <= 6'd0;
			{wrenOutC0, wrenOutC1} <= 2'b0;
		end
		else begin
			{addrOutC0, addrOutC1} <= {addrInC1, addrInC0};
			{dataOutC0, dataOutC1} <= {dataInC1, dataInC0};
			{funct3OutC0, funct3OutC1} <= {funct3InC1, funct3InC0};
			{wrenOutC0, wrenOutC1} <= {wrenInC1, wrenInC0};
		end
	end
endmodule

module main(
	input  clk, reset_n,
	output [31:0] dataDwb0, dataDwb1,
	output extStall
);
		// Coherency Signals
	wire [31:0] aluOutMem0, aluOutMem1, aluOutMemC0, aluOutMemC1;
	wire [31:0] dataBMem0, dataBMem1, dataBMemC0, dataBMemC1;
	wire [02:0] funct3Mem0, funct3Mem1, funct3MemC0, funct3MemC1;
	wire [00:0] dmemWren0, dmemWren1, dmemWrenC0, dmemWrenC1;
	// The Esteemed Core 0
	rv32i #(0) RV0(
		dataDwb0,
		// DMEM signal exposure for cache coherency
		aluOutMem0, dataBMem0,
		funct3Mem0, dmemWren0,
		// DMEM signal inlet for cache coherency. 'C' stands for Coherency Controller.
		aluOutMemC0, dataBMemC0,
		funct3MemC0, dmemWrenC0,
		// Input Signals
		extStall, clk, reset_n
	);
	// The Reverable Core 1
	rv32i #(1)RV1(
		dataDwb1,
		// DMEM signal exposure for cache coherency
		aluOutMem1, dataBMem1,
		funct3Mem1, dmemWren1,
		// DMEM signal inlet for cache coherency. 'C' stands for Coherency Controller.
		aluOutMemC1, dataBMemC1,
		funct3MemC1, dmemWrenC1,
		// Input Signals
		extStall, clk, reset_n
	);
	
	coherencyController CC0(
		.extStall(extStall),
		// Out Ports. Will serve as inputs to Ext ports of both processors.
		.addrOutC0(aluOutMemC0), .addrOutC1(aluOutMemC1),
		.dataOutC0(dataBMemC0), .dataOutC1(dataBMemC1),
		.funct3OutC0(funct3MemC0), .funct3OutC1(funct3MemC1),
		.wrenOutC0(dmemWrenC0), .wrenOutC1(dmemWrenC1),
		// In Ports. Will collect Int Inputs from both processors.
		.addrInC0(aluOutMem0), .addrInC1(aluOutMem1),
		.dataInC0(dataBMem0), .dataInC1(dataBMem1),
		.funct3InC0(funct3Mem0), .funct3InC1(funct3Mem1),
		.wrenInC0(dmemWren0), .wrenInC1(dmemWren1),
		// clk and co.
		
		.clk(clk), .reset(reset_n)
	);
endmodule
/*
module testbench;
	reg  clk, reset_n;
	wire [31:0] dataDwb0, dataDwb1;
	
	wire extStall;
	// Coherency Signals
	wire [31:0] aluOutMem0, aluOutMem1, aluOutMemC0, aluOutMemC1;
	wire [31:0] dataBMem0, dataBMem1, dataBMemC0, dataBMemC1;
	wire [02:0] funct3Mem0, funct3Mem1, funct3MemC0, funct3MemC1;
	wire [00:0] dmemWren0, dmemWren1, dmemWrenC0, dmemWrenC1;
	// The Esteemed Core 0
	rv32i #(0) RV0(
		dataDwb0,
		// DMEM signal exposure for cache coherency
		aluOutMem0, dataBMem0,
		funct3Mem0, dmemWren0,
		// DMEM signal inlet for cache coherency. 'C' stands for Coherency Controller.
		aluOutMemC0, dataBMemC0,
		funct3MemC0, dmemWrenC0,
		// Input Signals
		extStall, clk, reset_n
	);
	// The Reverable Core 1
	rv32i #(1)RV1(
		dataDwb1,
		// DMEM signal exposure for cache coherency
		aluOutMem1, dataBMem1,
		funct3Mem1, dmemWren1,
		// DMEM signal inlet for cache coherency. 'C' stands for Coherency Controller.
		aluOutMemC1, dataBMemC1,
		funct3MemC1, dmemWrenC1,
		// Input Signals
		extStall, clk, reset_n
	);
	
	coherencyController CC0(
		.extStall(extStall),
		// Out Ports. Will serve as inputs to Ext ports of both processors.
		.addrOutC0(aluOutMemC0), .addrOutC1(aluOutMemC1),
		.dataOutC0(dataBMemC0), .dataOutC1(dataBMemC1),
		.funct3OutC0(funct3MemC0), .funct3OutC1(funct3MemC1),
		.wrenOutC0(dmemWrenC0), .wrenOutC1(dmemWrenC1),
		// In Ports. Will collect Int Inputs from both processors.
		.addrInC0(aluOutMem0), .addrInC1(aluOutMem1),
		.dataInC0(dataBMem0), .dataInC1(dataBMem1),
		.funct3InC0(funct3Mem0), .funct3InC1(funct3Mem1),
		.wrenInC0(dmemWren0), .wrenInC1(dmemWren1),
		// clk and co.
		
		.clk(clk), .reset(reset_n)
	);
	
	integer i;
	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0, testbench);
		#0 reset_n = 1;
		#0 clk = 0;
		#1 reset_n = 0;
		#1 reset_n = 1;
		
		for(i=0; i<200; i=i+1)
			#1 clk = ~clk;
	end
endmodule
*/
