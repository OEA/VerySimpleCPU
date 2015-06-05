/*
	S001390 - Ömer Emre ASLAN
	author: @OEASLAN
	repo: VerySimpleCPU
	file: VerySimpleCPU.v
	github: https://github.com/OEASLAN/VerySimpleCPU 
		(it will be public when grade can be seen to handle plagiarism)
	date: 5 June 2015
	
*/

`timescale 1ns / 1ps
module SimpleCPU(clk, rst, data_fromRAM, wrEn, addr_toRAM, data_toRAM, pCounter);

parameter SIZE = 10;

input clk, rst;
input wire [31:0] data_fromRAM;
output reg wrEn;
output reg [SIZE-1:0] addr_toRAM;
output reg [31:0] data_toRAM;
output reg [SIZE-1:0] pCounter;

/* PARAMETERS START */

	// Fetch Instruction
	parameter FI = 0; 
	// Fetch operand1 = A
	parameter F1 = 1; 
	// Fetch operand2 = B
	parameter F2 = 2; 
	// Execute instructions without immediate
	parameter EX = 3; 
	// Write back
	parameter WR = 4; 
	// Execute instructions with immediate
	parameter IM = 5; 

/* PARAMETERS FINISH */

// internal signals
reg [ 3:0] opcode, opcodeNext;
reg [13:0] operand1, operand2, operand1Next, operand2Next;
reg [SIZE-1:0] /*pCounter,*/ pCounterNext;
reg [31:0] num1, num2, num1Next, num2Next;
reg [ 2:0] state, stateNext;


always @(posedge clk)begin
	state    <= #1 stateNext;
	pCounter <= #1 pCounterNext;
	opcode   <= #1 opcodeNext;
	operand1 <= #1 operand1Next;
	operand2 <= #1 operand2Next;
	num1     <= #1 num1Next;
	num2     <= #1 num2Next;
end

always @*begin
	stateNext    = state;
	pCounterNext = pCounter;
	opcodeNext   = opcode;
	operand1Next = operand1;
	operand2Next = operand2;
	num1Next     = num1;
	num2Next     = num2;
	addr_toRAM   = 0;
	wrEn         = 0;
	data_toRAM   = 0;
if(rst)
	begin
	stateNext    = 0;
	pCounterNext = 0;
	opcodeNext   = 0;
	operand1Next = 0;
	operand2Next = 0;
	num1Next     = 0;
	num2Next     = 0;
	addr_toRAM   = 0;
	wrEn         = 0;
	data_toRAM   = 0;
	end
else 
	case(state)                       
		FI: begin
			pCounterNext = pCounter;
			opcodeNext   = opcode;
			operand1Next = 0;
			operand2Next = 0;
			addr_toRAM   = pCounter;
			num1Next     = 0;
			num2Next     = 0;
			wrEn         = 0;
			data_toRAM   = 0;
			stateNext    = F1;
		end 
		F1:begin                   
			pCounterNext = pCounter;
			opcodeNext   = {data_fromRAM[28], data_fromRAM[31:29]};
			operand1Next = data_fromRAM[27:14];
			operand2Next = data_fromRAM[13: 0];
			addr_toRAM   = data_fromRAM[27:14];
			num1Next     = 0;
			num2Next     = 0;
			wrEn         = 0;
			data_toRAM   = 0;
			//All immediate instructions
			if(opcodeNext[3]==1)
				stateNext = IM;
			else
				stateNext = F2;
		end
		F2: begin        
			pCounterNext = pCounter;
			opcodeNext   = opcode;
			operand1Next = operand1;
			operand2Next = operand2;
			addr_toRAM   = operand2;
			num1Next     = data_fromRAM;
			num2Next     = 0;
			wrEn         = 0;
			data_toRAM   = 0;
			stateNext    = EX;
		end
		EX: begin            
			pCounterNext = pCounter + 1;
			opcodeNext = opcode;
			operand1Next = operand1;
			operand2Next = operand2;
			addr_toRAM = operand1;
			num1Next = num1;
			num2Next = data_fromRAM;
			wrEn = 1;
			stateNext = FI;
			case(opcodeNext)
					//ADD instruction
					4'b0000 : begin
						data_toRAM = num1Next + num2Next;
					end
					//NAND instruction
					4'b0001 : begin
						data_toRAM = ~(num1Next & num2Next);
					end
					//SRL instruction
					4'b0010 : begin
						if(num2Next < 32)
							data_toRAM = num1Next >> num2Next;
						else
							data_toRAM = num1Next << (num2Next - 32);
					end
					//LT instruction
					4'b0011 : begin
						if(num1Next < num2Next)
							data_toRAM = 1;
						else
							data_toRAM = 0;
					end
	 				//CP instruction
					4'b0100 : begin
						data_toRAM = num2Next;
					end
					//CPI instruction
					4'b0101 : begin
						stateNext = WR;
						pCounterNext = pCounter;
						addr_toRAM = data_fromRAM;
						wrEn = 0;
					end
					//BZJ instruction
					4'b0110 : begin
						if(num2Next == 0)
							pCounterNext = num1Next;
						else
							pCounterNext = pCounter + 1;
					end
					//MUL instruction
					4'b0111 : begin
						data_toRAM = num1Next * num2Next;
					end
				endcase
		end
		WR: begin
			pCounterNext = pCounter + 1;
			opcodeNext   = opcode;
			operand1Next = operand1;
			operand2Next = operand2;
			num1Next     = num1;
			num2Next     = num2;
			wrEn         = 1;
			stateNext    = FI;
			//CPI addresses
			if(opcodeNext==4'b0101) begin
				addr_toRAM = operand1;
				data_toRAM = data_fromRAM;
			end
		end
		IM: begin
			pCounterNext = pCounter+1;//default
			opcodeNext   = opcode;
			operand1Next = operand1;
			operand2Next = operand2;
			addr_toRAM   = operand1;	
			num1Next     = data_fromRAM;
			num2Next     = operand2;
			wrEn         = 1;
			data_toRAM   = 32'hFFFF_FFFF;//default
			stateNext = 0;
			case(opcodeNext)
					//ADDi instruction
					4'b1000 : begin
						data_toRAM = num1Next + operand2;
					end
					//NANDi instruction
					4'b1001 : begin
						data_toRAM = ~(num1Next & operand2);
					end
					//SRLi instruction
					4'b1010 : begin
						if(num2Next < 32)
							data_toRAM = num1Next >> operand2;
						else
							data_toRAM = num1Next << (operand2 - 32);
					end
					//LTi instruction
					4'b1011 : begin
						if(num1Next < operand2)
							data_toRAM = 1;
						else
							data_toRAM = 0;
						end
					//CPi instruction
					4'b1100 : begin
						data_toRAM = operand2;
					end
					//CPIi instruction
					4'b1101 : begin
						addr_toRAM = num1Next;
						data_toRAM = num2Next;
					end
					//BZJi instruction
					4'b1110 : begin
					  wrEn=0;
					  pCounterNext = num1Next + operand2;
					end
					//MULi instruction
					4'b1111 : begin
						data_toRAM = num1Next * operand2;
					end
				endcase
		end
		default: begin
			stateNext    = 0;
			pCounterNext = 0;
			opcodeNext   = 0;
			operand1Next = 0;
			operand2Next = 0;
			num1Next     = 0;
			num2Next     = 0;
			addr_toRAM   = 0;
			wrEn         = 0;
			data_toRAM   = 0;
		end
	endcase

end
endmodule