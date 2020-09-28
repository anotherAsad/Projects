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


module PF_compute_unit
    #( 
        parameter LIN_WIDTH = 10
     )
	(
	    input clk,
        input res,
        input cntrl,
        input din_valid,
        input [1 : 0] op_type,
        input [15 : 0] din,
        
        output reg [15 : 0] data_out,
        output reg dout_valid
	);   
    
    //control parameters input from address FSM
    localparam CYCLE = 1'b0, START_CYCLE = 1'b1;
    //operation types
    localparam AVG = 2'b00, MIN = 2'b01, MAX = 2'b10;

    // internal signals
    reg d1_din_valid;
    reg [15 : 0] d1_din;
    reg [15 : 0] res_buf;
    reg valid_buf;
    integer i;

    always@(posedge clk) begin
        if(!res) begin
           d1_din_valid <= din_valid;
           d1_din <= din;
           valid_buf <= 1'b0;
           res_buf <= 16'd0;
           dout_valid <= 1'b0;          // output is invalid
           data_out <= 16'd0;
        end
        
        else begin
            d1_din_valid <= din_valid;
            d1_din <= din;
            case(cntrl)
                START_CYCLE:   
                    begin                        
			            res_buf <= d1_din;
			            valid_buf <= d1_din_valid;
			            dout_valid <= valid_buf;
			            data_out <= res_buf;
                    end
                CYCLE:  
                    begin
                        case (op_type)
                            AVG:    
                                begin
                                    res_buf <= res_buf + d1_din;
                                end
                            MIN: 
                                begin
                                    if(res_buf <= d1_din)     res_buf <= res_buf;
                                    else                      res_buf <= d1_din;
                                end
                            MAX: 
                                begin
                                    if(res_buf >= d1_din)     res_buf <= res_buf;
                                    else                      res_buf <= d1_din;
                                end
                        endcase
                        valid_buf <= valid_buf & d1_din_valid;
                    end
             endcase
        end
    end 
endmodule



















