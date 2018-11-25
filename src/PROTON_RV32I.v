module proton_RV32I(RST, CLK1, CLK2);
	//Parameters begin
	parameter	DATA_LENGTH		=	32,
			ADDRESS_LINES		=	20,
			IMMEDIATE_LENGTH	= 	20,
			OPCODE_LENGTH		=	7,
			FUNCTION7_LENGTH	= 	7,
			FUNCTION3_LENGTH	= 	3,
			REGISTER_LENGTH		= 	5,				
			ID_LENGTH		= 	5,				
			INSTR_TYPE_LENGTH	=	2;
				
	parameter	ENABLE	=	1'b1,
			DISABLE	=	1'b0;
				
	parameter	RWRITE	=	2'b00,
			STORE	=	2'b01,
			LOAD	=	2'b10,
			BR	=	2'b11;
	
	parameter	CONCAT	=	8'b00000000;
	
	parameter	R_OPCODE	=	7'b0110011,		//FOR _ADD, _SUB, _AND, _OR, _XOR
			I_OPCODE	=	7'b0010011,		//FOR _ADDI, _ANDI, _ORI, _XORI
			LI_OPCODE	=	7'b0000011,		//ONLY FOR LOAD IMMEDIATE(_LW)
			BI_OPCODE	=	7'b1110011,		//ONLY FOR _EBREAK
			S_OPCODE	=	7'b0100011,		//ONLY FOR STORE WORD(_SW)
			B_OPCODE	=	7'b1100011,		//FOR _BEQ, _BNE
			UA_OPCODE	=	7'b0010111,		//ONLY FOR _AUIPC
			UL_OPCODE	=	7'b0110111;		//ONLY FOR _LUI
	
	//7 bit Function(Opcode Ext.)
	parameter	FUN7_0 	= 	7'b0000000,
			FUN7_1 	=	7'b0100000;
	
	//3 bit Function(Opcode Ext.)
	parameter	FUN3_0 	=	3'b000,
			FUN3_1	=	3'b001,
			FUN3_2	=	3'b010,
			FUN3_3	=	3'b011,
			FUN3_4	=	3'b100,
			FUN3_5	=	3'b101,
			FUN3_6	=	3'b110,
			FUN3_7	=	3'b111;
	
	//Internal Decoded Signal
	parameter	_ADD	=	5'b00000,
			_ADDI	=	5'b00001,
			_SUB	=	5'b00010,
			_OR	= 	5'b00011,
			_ORI	=	5'b00100,
			_XOR	= 	5'b00101,
			_XORI	=	5'b00110,
			_AND	= 	5'b00111,
			_ANDI	=	5'b01000,
			_LW	=	5'b01001,
			_EBREAK	=	5'b01010,
			_SW	=	5'b01011,
			_BEQ	=	5'b01100,
			_BNE	=	5'b01101,
			_AUIPC	=	5'b01110,
			_LUI	=	5'b01111,
			_SLT	=	5'b10000,
			_SLTI	=	5'b10001;
				
	//EBREAK 12 bit OPCODE(For decode stage)
	parameter	eBreak	= 	12'b000000000001;
	//Parameters end
	
	//Local Parameters begin
	localparam	ADDRESS_DEPTH	=	2**ADDRESS_LINES;
	//Local Parameters end	
	
	//PROCESSOR IO begin
	input	CLK1;
	input	CLK2;
	input	RST;	
	//PROCESSOR IO end
	
	//PROCESSOR SIGNALS begin
	reg	HALTED;
	reg	TAKEN_BRANCH;
	//PROCESSOR SIGNALS end	
	
	//Internal Memory(RAM), Internal Register(REG) begin
	reg	[DATA_LENGTH	-	1	:	0]	RAM	[ADDRESS_DEPTH	-	1	:	0];
	reg	[DATA_LENGTH	-	1	:	0]	REG	[DATA_LENGTH	-	1	:	0];
	//Internal Memory(RAM), Internal Register(REG) end
	
	//IF IO begin
	reg	[DATA_LENGTH	-	1	:	0]	IF_ID_IR;
	reg	[DATA_LENGTH	-	1	:	0]	IF_ID_PC;
	//Signals
	reg	[DATA_LENGTH	-	1	:	0]	PC;
	//IF IO end
	
	//ID IO begin
	reg	[ID_LENGTH		-	1	:	0]	ID_EX_OUT;
	reg	[REGISTER_LENGTH	-	1	:	0]	ID_EX_RD;
	reg	[DATA_LENGTH		-	1	:	0]	ID_EX_RS1;
	reg	[DATA_LENGTH		-	1	:	0]	ID_EX_RS2;
	reg	[DATA_LENGTH		-	1	:	0]	ID_EX_PC;
	reg	[DATA_LENGTH		-	1	:	0]	ID_EX_IR;
	reg	[IMMEDIATE_LENGTH	-	1	:	0]	ID_EX_IMM;
	//Signals
	reg	[FUNCTION7_LENGTH	-	1	:	0]	FUN7;
	reg	[FUNCTION3_LENGTH	-	1	:	0]	FUN3;
	reg 	[REGISTER_LENGTH	-	1	:	0]	RS1;
	reg	[REGISTER_LENGTH	-	1	:	0]	RS2;
	reg	[REGISTER_LENGTH	-	1	:	0]	RD;
	reg	[OPCODE_LENGTH		-	1	:	0]	OPCODE;
	reg	[DATA_LENGTH		-	1	:	0]	ID_OUT;
	//ID IO end
	
	//EU IO begin
	reg	[DATA_LENGTH		-	1	:	0]	EX_MEM_OUT;
	reg	[DATA_LENGTH		-	1	:	0]	EX_MEM_RS2;
	reg	[REGISTER_LENGTH	-	1	:	0]	EX_MEM_RD;
	reg	[INSTR_TYPE_LENGTH	-	1	:	0]	EX_MEM_TYPE;
	reg	[DATA_LENGTH		-	1	:	0]	EX_MEM_PC;
	reg								EX_MEM_HALT;
	reg								EX_MEM_BREN;
	//Signals
	reg	[ID_LENGTH	-	1	:	0]	ID_IN;
	reg	[DATA_LENGTH	-	1	:	0]	RS1_IN;
	reg	[DATA_LENGTH	-	1	:	0]	RS2_IN;
	reg	[DATA_LENGTH	-	1	:	0]	IMMEDIATE_DATA;
	//EU IO end
	
	//MEM IO begin
	reg	[DATA_LENGTH		-	1	:	0]	MEM_WB_OUT;
	reg	[DATA_LENGTH		-	1	:	0]	MEM_WB_LOAD;
	reg	[DATA_LENGTH		-	1	:	0]	MEM_WB_RS2;
	reg	[REGISTER_LENGTH	-	1	:	0]	MEM_WB_RD;
	reg	[INSTR_TYPE_LENGTH	-	1	:	0]	MEM_WB_TYPE;
	reg								MEM_WB_HALT;
	//MEM IO end
	
	//WB IO begin
	reg	[DATA_LENGTH		-	1	:	0]	WB_LOAD;
	reg	[DATA_LENGTH		-	1	:	0]	WB_OUT;
	reg	[REGISTER_LENGTH	-	1	:	0]	WB_RD;
	//WB IO end
	
	//IF STAGE
	always @(posedge CLK1 or posedge RST) begin
		if(RST) begin
			IF_ID_IR	=	{DATA_LENGTH{DISABLE}};
			PC		=	{DATA_LENGTH{DISABLE}};
			IF_ID_PC	=	{DATA_LENGTH{DISABLE}};
			HALTED		=	DISABLE;
			TAKEN_BRANCH	=	DISABLE;
		end
		else if(!HALTED && !RST) begin
			IF_ID_PC	=	PC;
			if(EX_MEM_BREN) begin							//IF BRANCH ENABLE(BRANCHIN OCCURED) THEN EXECUTE THIS BLOCK
				IF_ID_IR	=	RAM[EX_MEM_OUT];			//READ INSTRUCTION FROM RAM
				TAKEN_BRANCH	=	ENABLE;					//ENABLE TAKEN_BRANCH CONTROL SIGNAL
				PC		=	EX_MEM_OUT	+	1;		//INCREMENT PC
			end
			else begin								//NORMAL EXECUTION
				IF_ID_IR	=	RAM[PC];				//FETCH INSTRUCTION FROM RAM
				PC		=	PC	+	1;			//INCREMENT PC
			end
		end
	end
	
	//ID STAGE
	always @(posedge CLK2 or posedge RST) begin
		if(RST) begin
			ID_EX_OUT	=	{ID_LENGTH{DISABLE}};
			ID_EX_PC	=	{DATA_LENGTH{DISABLE}};
			ID_EX_RD	=	{REGISTER_LENGTH{DISABLE}};
			ID_EX_RS1	=	{REGISTER_LENGTH{DISABLE}};
			ID_EX_RS2	=	{REGISTER_LENGTH{DISABLE}};
			ID_EX_IMM	=	{IMMEDIATE_LENGTH{DISABLE}};
			HALTED		=	DISABLE;
			TAKEN_BRANCH	=	DISABLE;
		end
		
		else if(!HALTED && !RST) begin
			ID_EX_IR				=	IF_ID_IR;	//ASSIGN FETCHED INSTRUCTION DECODE STAGE
			{FUN7, RS2, RS1, FUN3, RD, OPCODE} 	= 	ID_EX_IR;	//EXPAND THE INSTRUCTION IN R-TYPE FORMAT
			ID_EX_PC				=	IF_ID_PC;	//SEND PC TO EXECUTION UNIT SO THAT IT CAN BE ADDED IN BRANCH IMMEDIATE
			case(OPCODE)							//DECODE INSTRUCTION ON THE BASIS OF OPCODE -> FUN7 -> FUN3, AND ACCORDING TO FUN3 ASSIGN ID_OUT TO INTERNAL DECODED SIGNAL.
				R_OPCODE	:	begin
								case(FUN7)
									FUN7_0	:	begin
												case(FUN3)
													FUN3_0	:	ID_OUT 	= 	_ADD;
													FUN3_2	:	ID_OUT	=	_SLT;
													FUN3_4	:	ID_OUT	=	_XOR;
													FUN3_6	:	ID_OUT	=	_OR;
													FUN3_7	:	ID_OUT	=	_AND;
												endcase
											end
									FUN7_1	:	begin
												case(FUN3)
													FUN3_0	:	ID_OUT 	= 	_SUB;
												endcase
											end
									endcase
								end
				I_OPCODE	:	begin
								case(FUN3)
									FUN3_0	:	ID_OUT	=	_ADDI;
									FUN3_2	:	ID_OUT	=	_SLTI;
									FUN3_4	:	ID_OUT	=	_XORI;
									FUN3_6	:	ID_OUT	=	_ORI;
									FUN3_7	:	ID_OUT	=	_ANDI;
								endcase
							end
				LI_OPCODE	:	begin
								case(FUN3)
									FUN3_2	:	ID_OUT	=	_LW;
								endcase
							end
				BI_OPCODE	:	begin
								case({FUN7, RS2})
									eBreak	:	ID_OUT	=	_EBREAK;
								endcase
							end
				S_OPCODE	:	begin
								case(FUN3)
									FUN3_2	:	ID_OUT	=	_SW;
								endcase
							end
				B_OPCODE	:	begin
								case(FUN3)
									FUN3_0	:	ID_OUT	=	_BEQ;
									FUN3_1	:	ID_OUT	=	_BNE;
								endcase
							end
				UA_OPCODE	:	begin
								ID_OUT	=	_AUIPC;
							end
				UL_OPCODE	:	begin
								ID_OUT	=	_LUI;
							end
			endcase
			case(ID_OUT)										//ACCORDING TO ID_OUT FETCH DATA OF RS1 AND RS2, ASSIGN RD TO ID_EX_RD, CALCULATE IMMEDIATE IF REQUIRED.
				_ADD, _SUB, _AND, _OR, _XOR, _SLT	:
					begin
						ID_EX_RD 	= 	RD;
						ID_EX_RS1	=	(RS1 ==	{REGISTER_LENGTH{DISABLE}})	?	{DATA_LENGTH{DISABLE}}	:	REG[RS1];
						ID_EX_RS2	=	(RS2 ==	{REGISTER_LENGTH{DISABLE}})	?	{DATA_LENGTH{DISABLE}}	:	REG[RS2];
						ID_EX_OUT	=	ID_OUT;
					end
				_ADDI, _XORI, _ORI, _ANDI, _LW, _SLTI	:
					begin
						ID_EX_RD 	= 	RD;
						ID_EX_RS1	=	(RS1 ==	{REGISTER_LENGTH{DISABLE}})	?	{DATA_LENGTH{DISABLE}}	:	REG[RS1];
						ID_EX_IMM	=	{{8{FUN7[6]}}, FUN7, RS2};
						ID_EX_OUT	=	ID_OUT;
					end
				_EBREAK	:
					begin
						ID_EX_RD 	= 	RD;
						ID_EX_RS1	=	(RS1 ==	{REGISTER_LENGTH{DISABLE}})	?	{DATA_LENGTH{DISABLE}}	:	REG[RS1];
						ID_EX_IMM	=	{CONCAT, FUN7, RS2};
						ID_EX_OUT	=	ID_OUT;
					end
				_SW		:
					begin
						ID_EX_RS1	=	(RS1 ==	{REGISTER_LENGTH{DISABLE}})	?	{DATA_LENGTH{DISABLE}}	:	REG[RS1];
						ID_EX_RS2	=	(RS2 ==	{REGISTER_LENGTH{DISABLE}})	?	{DATA_LENGTH{DISABLE}}	:	REG[RS2];
						ID_EX_IMM	=	{{8{FUN7[6]}}, FUN7, RD};
						ID_EX_OUT	=	ID_OUT;
					end
				_BEQ, _BNE	:
					begin
						ID_EX_RS1	=	(RS1 ==	{REGISTER_LENGTH{DISABLE}})	?	{DATA_LENGTH{DISABLE}}	:	REG[RS1];
						ID_EX_RS2	=	(RS2 ==	{REGISTER_LENGTH{DISABLE}})	?	{DATA_LENGTH{DISABLE}}	:	REG[RS2];
						ID_EX_IMM	=	{{8{FUN7[6]}}, RD[0], FUN7[5:0], RD[4:1], 1'b0};
						ID_EX_OUT	=	ID_OUT;
					end
				_AUIPC, _LUI	:
					begin
						ID_EX_RD	=	RD;
						ID_EX_IMM	=	{FUN7, RS2, RS1, FUN3};
						ID_EX_OUT	=	ID_OUT;
					end
			endcase
		end
	end
	
	//EX Stage
	always @(posedge CLK1 or posedge RST) begin
		if(RST) begin
			EX_MEM_OUT		=	{DATA_LENGTH{DISABLE}};
			EX_MEM_PC		=	{DATA_LENGTH{DISABLE}};
			EX_MEM_RS2		=	{DATA_LENGTH{DISABLE}};
			EX_MEM_RD		=	{REGISTER_LENGTH{DISABLE}};
			EX_MEM_TYPE		=	{INSTR_TYPE_LENGTH{DISABLE}};
			EX_MEM_BREN		=	DISABLE;
			EX_MEM_HALT		=	DISABLE;
			HALTED			=	DISABLE;
			TAKEN_BRANCH	=	DISABLE;
		end
		else if(!HALTED	&&	!RST) begin
			IMMEDIATE_DATA	=	{{12{ID_EX_IMM[19]}}, ID_EX_IMM};		//SIGN EXTEND IMMEDIATE TO 32-Bits
			RS1_IN		=	ID_EX_RS1;					//ASSIGN DATA OF RS1 to RS1_IN
			RS2_IN		=	ID_EX_RS2;					//ASSIGN DATA OF RS2 to RS2_IN
			EX_MEM_RS2	=	ID_EX_RS2;					//ASSIGN DATA OF RS2 to EX_MEM_RS2 FOR STORE INSTRUCTION.
			ID_IN		=	ID_EX_OUT;					//ASSIGN DECODED INSTRUCTION TO ID STAGE
			EX_MEM_RD	=	ID_EX_RD;					//ASSIGN DESTINATION REGISTER ADDRESS FOR WB STAGE.
			TAKEN_BRANCH	=	DISABLE;					//DISABLE TAKEN BRANCH
			EX_MEM_PC	=	ID_EX_PC;					//PC THAT WILL CREATE NEW BRANCH ADDRESS.
			case(ID_IN)								//ALU
				_ADD	:	begin
							EX_MEM_OUT	=	RS1_IN	+	RS2_IN;
							EX_MEM_TYPE	=	RWRITE;
						end
				_ADDI	:	begin
							EX_MEM_OUT	=	RS1_IN	+	IMMEDIATE_DATA;
							EX_MEM_TYPE	=	RWRITE;
						end
				_SUB	:	begin
							EX_MEM_OUT	=	RS1_IN	-	RS2_IN;
							EX_MEM_TYPE	=	RWRITE;
						end
				_OR	:	begin
							EX_MEM_OUT	=	RS1_IN	|	RS2_IN;
							EX_MEM_TYPE	=	RWRITE;
						end
				_ORI	:	begin
							EX_MEM_OUT	=	RS1_IN	|	IMMEDIATE_DATA;
							EX_MEM_TYPE	=	RWRITE;
						end
				_XOR	:	begin
							EX_MEM_OUT	=	RS1_IN	^	RS2_IN;
							EX_MEM_TYPE	=	RWRITE;
						end
				_XORI	:	begin
							EX_MEM_OUT	=	RS1_IN	^	IMMEDIATE_DATA;
							EX_MEM_TYPE	=	RWRITE;
						end
				_AND	:	begin
							EX_MEM_OUT	=	RS1_IN	&	RS2_IN;
							EX_MEM_TYPE	=	RWRITE;
						end
				_ANDI	:	begin
							EX_MEM_OUT	=	RS1_IN	&	IMMEDIATE_DATA;
							EX_MEM_TYPE	=	RWRITE;
						end
				_LW	:	begin	
							EX_MEM_OUT	=	RS1_IN	+	IMMEDIATE_DATA;
							EX_MEM_TYPE	=	LOAD;
						end
				_EBREAK	:	begin
							EX_MEM_OUT	=	IMMEDIATE_DATA;
							EX_MEM_TYPE	=	RWRITE;
							EX_MEM_HALT	=	ENABLE;
						end
				_SW	:	begin
							EX_MEM_OUT	=	RS1_IN	+	IMMEDIATE_DATA;
							EX_MEM_TYPE	=	STORE;
						end
				_BEQ	:	begin
							EX_MEM_BREN	=	(RS1_IN ==	RS2_IN);
							EX_MEM_OUT	=	EX_MEM_PC	+	IMMEDIATE_DATA;
							EX_MEM_TYPE	=	BR;
						end
				_BNE	:	begin
							EX_MEM_BREN	=	(RS1_IN	!=	RS2_IN);
							EX_MEM_OUT	=	EX_MEM_PC	+	IMMEDIATE_DATA;
							EX_MEM_TYPE	=	BR;
						end
				_AUIPC	:	begin
							EX_MEM_OUT	=	{IMMEDIATE_DATA[31:12], {12{DISABLE}}}	+	EX_MEM_PC;
							EX_MEM_TYPE	=	RWRITE;
						end
				_LUI	:	begin	
							EX_MEM_OUT	=	{IMMEDIATE_DATA[31:12], {12{DISABLE}}};
							EX_MEM_TYPE	=	RWRITE;
						end
				_SLT	:	begin
							EX_MEM_OUT	=	(RS1_IN	<	RS2_IN)	?	{DATA_LENGTH{ENABLE}}	:	{DATA_LENGTH{DISABLE}};
							EX_MEM_TYPE	=	RWRITE;
						end
				_SLTI	:	begin
							EX_MEM_OUT	=	(RS1_IN	<	IMMEDIATE_DATA)	?	{DATA_LENGTH{ENABLE}}	:	{DATA_LENGTH{DISABLE}};
							EX_MEM_TYPE	=	RWRITE;
						end
			endcase
			EX_MEM_BREN	=	(EX_MEM_TYPE == BR)	?	ENABLE	:	DISABLE;		//IF BR TYPE INSTRUCTION THEN ASSERT EX_MEM_BREN TO 1'b1 ELSE 1'b0
		end
	end
	
	//MEM Stage
	always @(posedge CLK2 or posedge RST) begin
		if(RST) begin
			MEM_WB_OUT	=	{DATA_LENGTH{DISABLE}};
			MEM_WB_LOAD	=	{DATA_LENGTH{DISABLE}};
			MEM_WB_RS2	=	{DATA_LENGTH{DISABLE}};
			MEM_WB_RD	=	{REGISTER_LENGTH{DISABLE}};
			MEM_WB_TYPE	=	{INSTR_TYPE_LENGTH{DISABLE}};
			MEM_WB_HALT	=	DISABLE;
			HALTED		=	DISABLE;
			TAKEN_BRANCH	=	DISABLE;
		end
		
		else if(!HALTED && !RST) begin
			MEM_WB_TYPE	=	EX_MEM_TYPE;								//ASSIGN MEMORY OPERATION TYPE.
			MEM_WB_RS2	=	EX_MEM_RS2;								//FOR STORE INSTRUCTION
			MEM_WB_RD	=	EX_MEM_RD;								//FOR WRITE BACK			
			MEM_WB_HALT	=	EX_MEM_HALT;								//IF EBREAK OCCURED THEN ASSERT THIS TO 1'b1 (CHECK PREVIOUS STAGE) THEN THIS WOULD BE CARRY FORWARDED TO WB STAGE TO ASSERT HALTED
			case(MEM_WB_TYPE)										//IF TYPE OF OPERATION IS REGISTER-REGISTER OR REGISTER IMMEDIATE THEN RWRITE WILL WORK, IF LOAD COMMAND THE LOAD WILL EXECUTE IF STORE THEN STORE WILL BE EXECUTED
				RWRITE	:	MEM_WB_OUT	=	EX_MEM_OUT;
				LOAD	:	MEM_WB_LOAD	=	RAM[EX_MEM_OUT];				//LOAD DATA TO A REGISTER THAT WOULD BE STORED IN DESTINATION REGISTER IN NEXT STAGE
				STORE	:	begin
							if(!TAKEN_BRANCH)
								RAM[EX_MEM_OUT]	=	MEM_WB_RS2;			//STORE THE VALUE OF RS2 IN RAM.
						end
			endcase
		end
	end
	
	//WB Stage
	always @(posedge CLK1 or posedge RST) begin
		if(RST) begin
			HALTED		=	DISABLE;
			TAKEN_BRANCH	=	DISABLE;
			WB_LOAD		=	{DATA_LENGTH{DISABLE}};
			WB_OUT		=	{DATA_LENGTH{DISABLE}};
			WB_RD		=	{REGISTER_LENGTH{DISABLE}};
		end
		
		else if(!HALTED && !RST) begin
			if(!TAKEN_BRANCH) begin
				WB_RD	=	MEM_WB_RD;								//DESTINATION REGISTER ADDRESS
				WB_OUT	=	MEM_WB_OUT;								//DATA TO BE WRITTEN IN REGISTERS
				WB_LOAD	=	MEM_WB_LOAD;								//DATA THAT WAS LOADED FROM RAM THAT WILL BE STORED IN REGISTER
				case(MEM_WB_TYPE)
					RWRITE	:	REG[WB_RD]	=	(WB_RD == 5'b00000) ? {DATA_LENGTH{DISABLE}} : WB_OUT;		//IF REGISTER-REGISTER OR REGISTER IMMEDIATE THEN WRITE DATA TO INTERNAL REGISTERS, IF REG ADDRESS IS 5'b00000 THEN WRITE 32'b0 IN THE MEMORY[0]
					LOAD	:	REG[WB_RD]	=	(WB_RD == 5'b00000) ? {DATA_LENGTH{DISABLE}} : WB_LOAD;		//IF LOAD, IF REG ADDRESS IS 5'b00000 THEN WRITE 32'b0 IN THE MEMORY[0]
				endcase
				HALTED	=	(MEM_WB_HALT)	?	ENABLE	:	DISABLE;			//ASSERT HALTED IF MEM_WB_HALT IS ENABLED ELSE DISABLE HALTED.(IF THE SYSTEM IS HALTED IT CAN ONLY EXIT THIS STATE IF IT IS RESET IS ASSERTED AGAIN).
			end
		end
	end
	
endmodule
