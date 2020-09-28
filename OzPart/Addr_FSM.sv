//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2020 01:45:10 PM
// Design Name: 
// Module Name: addr_FSM_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Addr_FSM
    #( 
        parameter LIN_WIDTH = 10
     )
	(
	    input clk,
        input res,
        input start,
        input [4 : 0] ver_jump,     //tile width - (filter_size - 1)
        input [1 : 0] filter_size,
        input [LIN_WIDTH - 1 : 0] start_addr,
        
        output reg Error,
        output reg [LIN_WIDTH - 1 : 0] addr_out,
        output reg addr_valid,
        output reg comp_unit_control,
        output reg done_out,
        
        //metadata 
        input [LIN_WIDTH - 1 : 0] top_simplejump,      // no_filters*stride
        input [LIN_WIDTH - 1 : 0] top_horjump,         // no_filters*stride + tile_width*(filter_width - 1) + 1 
        input [LIN_WIDTH - 1 : 0] top_verjump,         // no_filters*stride + tile_width*(filter_width - 1) + 1 + top_verjumpcase*tile_width  // top_verumpcase is tile_height % filter_height (in this case 7 % 3 = 1) 
        input [LIN_WIDTH - 1 : 0] horlim_init,
        input [LIN_WIDTH - 1 : 0] verlim_init,
        input [LIN_WIDTH - 1 : 0] horlim_stride1,      // filter_height*tile_width
        input [LIN_WIDTH - 1 : 0] horlim_stride2,      // (halo_height + 1)*tile_width
        input [LIN_WIDTH - 1 : 0] verlim_stride
        
	);   
	 
    //FSM parameters
    localparam IDLE = 3'b000, ADDR_INIT = 3'b001, ADD_1 = 3'b010, ADD_VER = 3'b011, ADD_STR = 3'b100;
    
    // comp unit control parameters
    localparam CYCLE = 1'b0, START_CYCLE = 1'b1;

    // internal signals
    reg [LIN_WIDTH : 0] top_addr;
    reg [LIN_WIDTH : 0] btm_addr;
    reg [LIN_WIDTH : 0] next_topaddr;
    reg [LIN_WIDTH : 0] next_btmaddr;
    reg next_addrvalid;
    reg d1_addrvalid;
    reg h_esc;
    reg v_esc;
    reg [1 : 0] h_cnt;
    reg [1 : 0] next_hcnt;
    reg [1 : 0] v_cnt;
    reg [1 : 0] next_vcnt;
    reg [2 : 0] state;
    reg [2 : 0] next_state;
    reg d1_cuctrl;
    reg d2_cuctrl;
    reg d3_cuctrl;
 //   reg d4_cuctrl;
    reg cuctrl;
    reg done;
    reg addr_upper_lim;
    
    // one extra bit has been used on these registers so that overflow may be detected
    reg [LIN_WIDTH : 0] sum_topsimplejump;
    reg [LIN_WIDTH : 0] sum_tophorjump;
    reg [LIN_WIDTH : 0] sum_topverjump;
    reg [LIN_WIDTH : 0] sum_out;
    reg [LIN_WIDTH : 0] top_horlimit;
    reg [LIN_WIDTH : 0] top_verlimit;
    reg [LIN_WIDTH : 0] next_tophorlimit;
    reg [LIN_WIDTH : 0] next_topverlimit;
        
    always@(*)begin
        done_out = done & !addr_valid;
        addr_upper_lim = sum_out[LIN_WIDTH];
        
        if (h_cnt == (filter_size - 1)) h_esc = 1'b1;
        else h_esc = 1'b0;
        
        if (v_cnt == (filter_size - 1)) v_esc = 1'b1;
        else v_esc = 1'b0;
        
        case(state)
            IDLE :  begin
            			Error = 0;
                        next_hcnt = 2'b00;
                        next_vcnt = 2'b00;
                        next_addrvalid = 1'b0;
                        next_topaddr = 10'd0;
                        next_btmaddr = 10'd0;
                        if((start == 1'b1) && (done != 1'b1))    next_state <= ADDR_INIT;
                        else         next_state <= IDLE;
                        cuctrl = done ? START_CYCLE : CYCLE;  
                    end 
            ADDR_INIT :     begin
                                next_addrvalid = 1'b1;
                                next_topaddr = {1'b0, start_addr};
                                next_btmaddr = {1'b0, start_addr};
                                cuctrl = START_CYCLE;
                               Error = 0;
                                next_state = ADD_1;
                                next_hcnt = h_cnt + 2'b01;
                                next_vcnt = v_cnt;
                            end 
            ADD_1 :     begin
            				next_topaddr = {1'b0, start_addr};
                            next_addrvalid = 1'b1;
                            next_btmaddr = btm_addr + 10'd1;
                            cuctrl = CYCLE;
                            Error = 0;
                            if(h_esc & !v_esc) begin
                                next_state = ADD_VER;
                                next_hcnt = 2'b00;
                                next_vcnt = v_cnt + 2'b01;
                            end

// this case represents last cell of filter application. If done is raised, FSM should go to IDLE only from this state
                            else if(h_esc & v_esc) begin       
                                if(addr_upper_lim) begin
                                    next_state = IDLE;   
                                end      
                                else next_state = ADD_STR;
                                next_hcnt = 2'b00;
                                next_vcnt = 2'b00;
                            end

                            else begin
                                next_state = ADD_1;
                                next_hcnt = h_cnt + 2'b01;
                                next_vcnt = v_cnt;
                            end
                        end 
            ADD_VER :   begin
            				next_topaddr = {1'b0, start_addr};
                            next_addrvalid = 1'b1;
                            next_btmaddr = btm_addr + ver_jump;
                            cuctrl = CYCLE;
                            Error = 0;
                            next_state = ADD_1;
                            next_hcnt = h_cnt + 2'b01;
                            next_vcnt = v_cnt;
                        end 
            ADD_STR :   begin
            				next_topaddr = {1'b0, start_addr};
                            next_addrvalid = 1'b1;
                            next_topaddr = sum_out;
                            next_btmaddr = next_topaddr;                // this assigns updated top_addr to btm_addr      
                            cuctrl = START_CYCLE;
                            Error = 0;
                            next_state = ADD_1;
                            next_hcnt = h_cnt + 2'b01;
                            next_vcnt = v_cnt;
                        end 
            default :    begin
            				cuctrl = 1'b0;
            				next_btmaddr = 2'b0;
            				next_topaddr = {1'b0, start_addr};
            				next_vcnt = 2'b0;
                            next_state = IDLE;
                            next_addrvalid = 1'b1;
                            next_hcnt = 2'b0;
                            Error = 1;
                        end                        
        endcase
    end

    always@(posedge clk) begin
        if(!res) begin
            state <= IDLE;
            h_cnt <= 2'b00;
            v_cnt <= 2'b00;
            //Error <= 0;
            done <= 1'b0;
           // addr_out <= 10'd0;
            top_addr <= 10'd0;
            btm_addr <= 10'd0;
            top_horlimit <= horlim_init;
            top_verlimit <= verlim_init;
        end
        
        else begin
            addr_out <= btm_addr;
            state <= next_state;
            top_addr <= next_topaddr;
            btm_addr <= next_btmaddr;
            h_cnt <= next_hcnt;
            v_cnt <= next_vcnt;
           
            addr_valid <= d1_addrvalid;
            d1_addrvalid <= next_addrvalid;
            
            comp_unit_control <= d3_cuctrl;
            d3_cuctrl <= d2_cuctrl;
            d2_cuctrl <= d1_cuctrl;
            d1_cuctrl <= cuctrl;

            //generation of next_topaddr
            sum_topsimplejump <= top_addr + top_simplejump;
            sum_tophorjump <= top_addr + top_horjump;
            sum_topverjump <= top_addr + top_verjump;

            if(sum_topsimplejump > top_verlimit)   
                begin
                    sum_out <= sum_topverjump;                              // sum in case of exceeding vertical limit
                    next_topverlimit <= top_verlimit + verlim_stride;       // update vertical limit
                    next_tophorlimit <= top_horlimit + horlim_stride2;      // update horizontal limit as well
                end
            else if(sum_topsimplejump > top_horlimit)  
                begin
                    sum_out <= sum_tophorjump;                               // sum in case of exceeding horizontal limit
                    next_tophorlimit <= top_horlimit + horlim_stride1;       // update horizontal limit
                end
            else    
                begin
                    sum_out <= sum_topsimplejump;           // sum in case of keeping within limits
                    next_topverlimit <= top_verlimit;       // keep vertical limit
                    next_tophorlimit <= top_horlimit;       // keep horizontal limit as well
                end

            if(state == ADD_STR) 
                begin 
                    top_horlimit <= next_tophorlimit;
                    top_verlimit <= next_topverlimit;
                end
           
           if((state == ADD_1) && (h_esc == 1'b1) && (v_esc == 1'b1) && (addr_upper_lim == 1'b1)) 
                done <= 1'b1;
        end
    end  
endmodule


// remaining things:
// incorporate ending of FSM        (done)
// cater stride horizontal jump     (done)
// cater stride vertical (cross filter) jump    (done)
// incorporate control signals to comp_unit     (dones)






















