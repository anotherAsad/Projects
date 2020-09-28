module buff(out, in);
	output out;
	input  in;
	assign out = in;
endmodule

module Test(LEDR, SW);
	output [9:0] LEDR;
	input  [0:9] SW;
	
	generate
		genvar i;
		for (i=0; i<10; i=i+1) begin: m
			assign LEDR[i] = SW[i];
			//buff name(LEDR[i], SW[i]);
		end
	endgenerate
endmodule 