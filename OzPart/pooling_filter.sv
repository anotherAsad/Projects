//`include "Addr_FSM.v"
//`include "PF_compute_unit.v"
module pooling_filter #( 
        parameter RAM_UNITS = 32,
        parameter RAM_DEPTH = 32,
        parameter LIN_WIDTH = 10,
        parameter ACCUMULATOR_ADDR_WIDTH = 5,
        parameter POOLING_UNITS = 3 
     )
	(
	    input clk,
	    input res,
	    input [31 : 0][15 : 0] data_in,
        input valid_in,	// halo side facing
        input ready_in,
        
        // metadata inputs for Addr_FSM
        input [POOLING_UNITS - 1 : 0][9 : 0] start_addr,
        input [4 : 0] ver_jump,                        //tile width - (filter_size - 1)
        input [1 : 0] filter_size,
        input [LIN_WIDTH - 1 : 0] top_simplejump,      // no_filters*stride
        input [LIN_WIDTH - 1 : 0] top_horjump,         // no_filters*stride + tile_width*(filter_width - 1) + 1 
        input [LIN_WIDTH - 1 : 0] top_verjump,         // no_filters*stride + tile_width*(filter_width - 1) + 1 + top_verjumpcase*tile_width  // top_verumpcase is tile_height % filter_height (in this case 7 % 3 = 1) 
        input [LIN_WIDTH - 1 : 0] horlim_init,
        input [LIN_WIDTH - 1 : 0] verlim_init,
        input [LIN_WIDTH - 1 : 0] horlim_stride1,      // filter_height*tile_width
        input [LIN_WIDTH - 1 : 0] horlim_stride2,      // (halo_height + 1)*tile_width
        input [LIN_WIDTH - 1 : 0] verlim_stride,
        
        //metadata input for PF_compute units
        input [1 : 0] op_type,
        
        output reg [31 : 0][4 : 0] rd_addr,
        output reg [31 : 0] rd_en,
        output reg [2 : 0][15 : 0] muxed_data,       // to be edited out later
        output reg valid_out,
        output reg ready_out,
        
        //outputs from PF_compute units
        output wire [POOLING_UNITS - 1 : 0][15 : 0] data_out,
        output wire [POOLING_UNITS - 1 : 0] dout_valid
        
	);
// FSM parameters
localparam IDLE = 3'b000, FILL_STAGE1 = 3'b001, FILL_STAGE2 = 3'b010, FILL_STAGE3 = 3'b011, RUN = 3'b100;
reg [2 : 0] state;
reg [2 : 0] next_state;

// outputs for Addr_FSM units 
wire [POOLING_UNITS - 1 : 0] Error;
wire [POOLING_UNITS - 1 : 0][LIN_WIDTH - 1 : 0] addr;
wire [POOLING_UNITS - 1 : 0] addr_valid;
wire [POOLING_UNITS - 1 : 0] comp_unit_control;
wire [POOLING_UNITS - 1 : 0] done_out;

//signals for PF_compute unit
reg [POOLING_UNITS - 1 : 0]  PF_valid_in;

//internal
reg [15 : 0] in_reg [63 : 0];
reg [LIN_WIDTH - 1 : 0] addr_prev; 
reg [1 : 0] valid;
reg d1_rden;
reg addr_fsm_en;
reg done;
integer i;

genvar l;
generate

    for(l = 0; l < POOLING_UNITS; l = l + 1) begin: addrFSM
            
            Addr_FSM
            #( 
                .LIN_WIDTH(LIN_WIDTH)
             )
             
             ADRFSM
             
            (
                .clk(clk),
                .res(res),
                .start(addr_fsm_en),
                .ver_jump(ver_jump),
                .filter_size(filter_size),
                .start_addr(start_addr[l]),
                        
                .Error(Error[l]),
                .addr_out(addr[l]),
                .addr_valid(addr_valid[l]),
                .comp_unit_control(comp_unit_control[l]),
                .done_out(done_out[l]),
                
                //metadata 
                .top_simplejump(top_simplejump),      // no_filters*stride
                .top_horjump(top_horjump),         // no_filters*stride + tile_width*(filter_width - 1) + 1 
                .top_verjump(top_verjump),         // no_filters*stride + tile_width*(filter_width - 1) + 1 + top_verjumpcase*tile_width  // top_verumpcase is tile_height % filter_height (in this case 7 % 3 = 1) 
                .horlim_init(horlim_init),
                .verlim_init(verlim_init),
                .horlim_stride1(horlim_stride1),      // filter_height*tile_width
                .horlim_stride2(horlim_stride2),      // (halo_height + 1)*tile_width
                .verlim_stride(verlim_stride)
                
            );   
    end              
endgenerate 

genvar k;
generate

    for(k = 0; k < POOLING_UNITS; k = k + 1) begin: PF_comp
        PF_compute_unit
            #( 
                .LIN_WIDTH(LIN_WIDTH)
             )
             
             PFC
             
            (
                .clk(clk),
                .res(res),
                .cntrl(comp_unit_control[k]),
                .din_valid(PF_valid_in[k]),       // fill this
                .op_type(op_type),
                .din(muxed_data[k]),
                
                .data_out(data_out[k]),
                .dout_valid(dout_valid[k])
            );   
    end
endgenerate

generate
	genvar j;
	for (j = 0; j < 3; j = j + 1) begin: m
		always @(posedge clk) begin
			muxed_data[j] <= in_reg[addr[j][5 : 0]];
			PF_valid_in[j] <= valid[addr[j][5]] & addr_valid[j];
		end
	end
endgenerate

always@(*) begin
    done = &done_out;//((done_out[0] & done_out[1]) & done_out[3]);     // to be parametrized; can use &done_out as well
	valid_out = done;
	ready_out = ready_in;

	case(state) 
		IDLE: begin
			if((valid_in == 1'b1) && (done != 1'b1)) next_state = FILL_STAGE1;
			else next_state = IDLE;
		end

		FILL_STAGE1: next_state = FILL_STAGE2;

		FILL_STAGE2: next_state = FILL_STAGE3;
		
		FILL_STAGE3: next_state = RUN;

		RUN: begin
			if(done == 1'b1) next_state = IDLE;
			else next_state = RUN;
		end

		default: next_state = IDLE;
	endcase
	
end

always@(posedge clk) begin
	d1_rden <= rd_en[0];

    if(!res) begin
		rd_en <= 32'b0;
//		for (i = 0; i < 3; i = i + 1) begin       // to replace with addr_FSM
//			addr[i] <= start_addr + 2*i;
//		end
		for (i = 0; i < 64; i = i + 1) begin	  // can be taken out; validity check exists
			in_reg[i] <= 10'b0;
		end
		valid <= 2'b00;
		//valid_out <= 1'b0;
		state <= IDLE;
		addr_prev <= addr[0];
	 end
	 
	 else begin
		state <= next_state;
		addr_prev <= addr[0];

		case(state) 
			IDLE: begin
				rd_en[0] <= 1'b0;
				addr_fsm_en <= 1'b0;
			end

			FILL_STAGE1: begin
			
				rd_en[0] <= 1'b1;
				addr_fsm_en <= 1'b1;        //start the addressing FSM as well
				for (i = 0; i < 32; i = i + 1) begin
					rd_addr[i] <= start_addr[0][9 : 5];		
				end

			end

			FILL_STAGE2: begin
			
				rd_en[0] <= 1'b1;
				for (i = 0; i < 32; i = i + 1) begin
					rd_addr[i] <= start_addr[0][9 : 5] + 1'b1;		
				end
				
			end

            FILL_STAGE3: begin
                
                rd_en[0] <= 1'b0;
                if(d1_rden) begin
					// update upper half
					for(i = 0; i < 32; i = i + 1) begin
						in_reg[i] <= data_in[i];
					end
				end
				
				valid[0] <= 1'b1;       // update validity
				
            end
			RUN: begin
				
				rd_en[0] <= addr_prev[5] ^ addr[0][5];
				
				// valid logic
				if(addr_prev[5] != addr[0][5]) begin
					if(addr[0][5] == 1'b1)
						valid[0] <= 1'b0;
					else 
						valid[1] <= 1'b0;
				end

				else if(d1_rden == 1'b1) begin
					if(addr[0][5] == 1'b1)
						valid[0] <= 1'b1;
					else 
						valid[1] <= 1'b1;
				end

				// assigning read_addresses. These pick data from Halo output
				for (i = 0; i < 32; i = i + 1) begin
					rd_addr[i] <= addr[0][9 : 5] + 5'd1;		// improvement: registered 
				end

//				for (i = 0; i < 3; i = i + 1) begin
//					addr[i] <= addr[i] + 10'd2;
//				end		

				if(d1_rden) begin
					if(addr[0][5] == 1'b1) begin		// if pooling filters are working on lower half, update upper half
						for(i = 0; i < 32; i = i + 1) begin
							in_reg[i] <= data_in[i];
						end
					end
					else if(addr[0][5] != 1'b1) begin	// if pooling filters are working on upper half, update lower half
						for(i = 0; i < 32; i = i + 1) begin
							in_reg[i + 32] <= data_in[i];
						end
					end
				end
				
			end
		endcase
	 end
end

endmodule
