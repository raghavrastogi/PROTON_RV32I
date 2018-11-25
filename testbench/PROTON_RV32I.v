module proton_RV32I_TB;
	
	reg	CLK1;
	reg	CLK2;
	reg	RST;
	
	integer i;
	
	proton_RV32I DUT(RST, CLK1, CLK2);
	
	initial begin
		RST 	= 	1'b1;
		CLK1	= 	1'b0;
		CLK2	=	1'b0;
		forever begin
			#5	CLK1 	=	1'b1;
			#5	CLK1	=	1'b0;
			#5	CLK2 	=	1'b1;
			#5	CLK2	=	1'b0;
		end
	end
	
	initial begin
		#10
		for(i = 0; i < 31; i = i + 1) begin
			DUT.REG[i] = i;
		end
		
		DUT.RAM[0]	=	32'h003100B3;
		DUT.RAM[1]	=	32'h00010233;
		DUT.RAM[2]	=	32'h0001E2B3;
		DUT.RAM[3]	=	32'h00316333;
		DUT.RAM[4]	=	32'h0001F3B3;
		DUT.RAM[5]	=	32'h0011F433;
		DUT.RAM[6]	=	32'h00100073;
	end
	
	initial begin
		#10
		RST = 1'b0;
		#280
		for(i = 0; i < 9; i = i + 1) begin
			$display("R%1d	-	%2d", i , DUT.REG[i]);
		end
	end
endmodule
