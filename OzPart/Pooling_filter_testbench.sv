//`include "pooling_filter.v"
module pooling_filter_tb(
	//inputs 
	input clk, res,
	// output
	output [31:0] finOut
);
	parameter RAM_UNITS = 32;
	parameter RAM_DEPTH = 32;
	parameter POOLING_UNITS = 3;
	parameter LIN_WIDTH = 10;
	parameter ACCADDRWD = 5;

	reg [31:0][15:0] data_in;
	
reg [15:0] halo_out [RAM_UNITS-1:0][RAM_DEPTH-1:0];
	//inputs 
	reg valid_in;	// halo side facing
	reg ready_in;	// compression side facing

	// inputs; for Addr_FSM units (3 units)
	reg [2:0][LIN_WIDTH - 1 : 0] start_addr;

	// metadate input for Addr_FSM units (3 units)
	reg [1:0] filter_size;
	reg [4:0] ver_jump;					// tile width - (filter_size - 1)
	reg [LIN_WIDTH-1:0] top_simplejump;	// no_filters*stride
	reg [LIN_WIDTH-1:0] top_horjump;	// no_filters*stride + tile_width*(filter_width - 1) + 1 
	reg [LIN_WIDTH-1:0] top_verjump;	// no_filters*stride + tile_width*(filter_width - 1) + 1 + top_verjumpcase*tile_width 
										// top_verumpcase is tile_height % filter_height (in this case 7 % 3 = 1) 
	reg [LIN_WIDTH-1:0] horlim_init;	// address of first halo after start_addr
	reg [LIN_WIDTH-1:0] verlim_init;	// tile_width*tile_height - tile_width*halo_height - halo_width
	reg [LIN_WIDTH-1:0] horlim_stride1;	// filter_height*tile_width
	reg [LIN_WIDTH-1:0] horlim_stride2;	// (halo_height + 1)*tile_width
	reg [LIN_WIDTH-1:0] verlim_stride;	// tile_width*tile_width

	// metadata input for PF_compute
	reg [1:0] op_type;
	reg [31:0] rd_en;
	// outputs from PF_compute
	wire [POOLING_UNITS-1:0][15:0] data_out;
	wire [POOLING_UNITS-1:0]dout_valid;
		
	//outputs
	wire [31:0][4:0] rd_addr ;
	
	wire [2:0][15:0] muxed_data;
	wire valid_out;
	wire ready_out;

	//internal
	integer i, j;

	pooling_filter #(RAM_UNITS, RAM_DEPTH, LIN_WIDTH, ACCADDRWD, POOLING_UNITS) PF1(
		.clk(clk),
		.res(res),
		.data_in(data_in),         
		.valid_in(valid_in),	// halo side facing
		.ready_in(ready_in),
		    
		.start_addr(start_addr),
		.ver_jump(ver_jump),
		.filter_size(filter_size),
		.top_simplejump(top_simplejump),	// no_filters*stride
		.top_horjump(top_horjump),			// no_filters*stride + tile_width*(filter_width - 1) + 1 
		.top_verjump(top_verjump),			// no_filters*stride + tile_width*(filter_width-1)+1+ top_verjumpcase*tile_width 
											// top_verumpcase is tile_height % filter_height (in this case 7 % 3 = 1) 
		.horlim_init(horlim_init),
		.verlim_init(verlim_init),
		.horlim_stride1(horlim_stride1),      // filter_height*tile_width
		.horlim_stride2(horlim_stride2),      // (halo_height + 1)*tile_width
		.verlim_stride(verlim_stride),
		    
		.op_type(op_type),
		    
		.rd_addr(rd_addr), 
		//.rd_en(),
		.muxed_data(muxed_data),      
		.valid_out(valid_out),
		.ready_out(ready_out),
		    
		.data_out(data_out),
		.dout_valid(dout_valid)
	);

	always@(posedge clk) begin
		if(rd_en[0]) begin
			for(i=0; i<32; i=i+1)
				data_in[i] <= halo_out[i][rd_addr[i]];
		end
	end

	always @(*) begin
		finOut <= data_out[0] + data_out[1]+ data_out[2];
	end
	
	initial begin
		/*
		$dumpfile("test.vcd");
		$dumpvars(0);
			*/
		for(i = 0; i < RAM_UNITS; i = i + 1) begin
			for(j = 0; j < RAM_DEPTH; j = j + 1) begin
				halo_out[i][j] = (i + j*32);
			end
		end
	
		valid_in = 1'b1;
		ready_in = 1'b1;
		rd_en = 32'b1;
		// Addr_FSM metadata
		start_addr[0] = 10'd0;
		start_addr[1] = 10'd3;
		start_addr[2] = 10'd3;  // making one filter unit redundant, because for 3 3-stride filters,
								//you need tile_width of at least 9
		filter_size = 2'd3;
		ver_jump = 5'd5;        // 7 - (3 - 1)
		top_simplejump = 10'd6; // 2*3
		top_horjump = 10'd21;   // 2*3 + 7*(3 - 1) + 1
		top_verjump = 10'd28;   // 2*3 + 7*(3 - 1) + 1 + 1*7
		horlim_init = 10'd5;
		verlim_init = 10'd33;   // 7*7 - 7*2 - 2
		horlim_stride1 = 10'd21;    // 3*7
		horlim_stride2 = 10'd21;    // 3*7
		verlim_stride = 10'd49;
		
		//PF_compute metadata
		op_type = 2'b10;		// Max Pool opcode
		/*
		clk = 0;
		res = 0; #4; res = 1;
		
		for(i=0; i<100; i=i+1)
			#1 clk = ~clk;
		*/
	end
endmodule



//
////metadata for 2x2 filter 
//start_addr[0] = 10'd0;
//start_addr[1] = 10'd2;
//start_addr[2] = 10'd4;
//filter_size = 2'd2;
//ver_jump = 5'd6;
//top_simplejump = 10'd6; // 2*3
//top_horjump = 10'd14;   // 2*3 + 7*(2 - 1) + 1
//top_verjump = 10'd21;   // 2*3 + 7*(2 - 1) + 1 + 1*7
//horlim_init = 10'd5;
//verlim_init = 10'd33;
//horlim_stride1 = 10'd14;    // 2*7
//horlim_stride2 = 10'd21;    // 3*7
//verlim_stride = 10'd49;
//


//
////metadata for 3x3 filter 
//start_addr[0] = 10'd0;
//start_addr[1] = 10'd3;
//start_addr[2] = 10'd3;  // making one filter unit redundant, because for 3 3-stride filters, you need tile_width of at least 9
//filter_size = 2'd3;
//ver_jump = 5'd5;        // 7 - (3 - 1)
//top_simplejump = 10'd6; // 2*3
//top_horjump = 10'd21;   // 2*3 + 7*(3 - 1) + 1
//top_verjump = 10'd28;   // 2*3 + 7*(3 - 1) + 1 + 1*7
//horlim_init = 10'd5;
//verlim_init = 10'd33;   // 7*7 - 7*2 - 2
//horlim_stride1 = 10'd21;    // 3*7
//horlim_stride2 = 10'd21;    // 3*7
//verlim_stride = 10'd49;
//




