// The lab provided asks for a byte-wide 2x1 MUX.
// Since we do not have 16 switches available, we will make a nibble wide 2x1 MUX.
module code(LEDG, LEDR, SW, KEY);
	output [9:0] LEDG;
	output [9:0] LEDR;
	input  [9:0] SW;
	input  [3:3] KEY;
	
	// Remember, KEYs are originally High.
	wire [3:0] extendedS = {4{~KEY}};
	// Seperate mux output for understanding reasons only.
	wire [3:0] mux = (SW[3:0] & ~extendedS) | (SW[9:6] & extendedS);
	
	assign LEDR = {SW[9:6], 2'b0,SW[3:0]};
	assign LEDG = mux;
endmodule
