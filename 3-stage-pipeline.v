// Behavioral model of MIPS, 3-stage pipeline for R-types and addi only
// Implements forwarding
module reg_file (RR1,RR2,WR,WD,RegWrite,RD1,RD2,clock);
  input [4:0] RR1,RR2,WR;
  input [31:0] WD;
  input RegWrite,clock;
  output [31:0] RD1,RD2;
  reg [31:0] Regs[0:31];
  assign RD1 = Regs[RR1];
  assign RD2 = Regs[RR2];
  initial Regs[0] = 0;
  always @(negedge clock)
    if (RegWrite==1 & WR!=0) 
	Regs[WR] <= WD;
endmodule

module alu (ALUctl,A,B,ALUOut,Zero);
  input [3:0] ALUctl;
  input [31:0] A,B;
  output reg [31:0] ALUOut;
  output Zero;
  always @(ALUctl, A, B) // reevaluate if these change
    case (ALUctl)
      4'b0000: ALUOut <= A & B;
      4'b0001: ALUOut <= A | B;
      4'b0010: ALUOut <= A + B;
      4'b0110: ALUOut <= A - B;
      4'b0111: ALUOut <= A < B ? 1:0;
      4'b1100: ALUOut <= ~A & ~B;
      4'b1101: ALUOut <= ~A | ~B;
      default: ALUOut <= 0;
    endcase
  assign Zero = (ALUOut==0); // Zero is true if ALUOut is 0
endmodule

//same main control from project1
module MainControl (Op,Control); 
  input [5:0] Op;
  output reg [6:0] Control; 
// Control bits: RegDst,ALUSrc,RegWrite,ALUctl this would be 7 bits, change control
  always @(Op) case (Op)
    //CHANGE THIS TO 7 BIT because of 4 bit ALUctl
    6'b000000: Control <= 5'b10110; // Rtype 
    6'b001000: Control <= 5'b01100; // ADDI
  endcase
endmodule

//do not need
// module ALUControl (ALUOp,FuncCode,ALUCtl); 
//   input [1:0] ALUOp;
//   input [5:0] FuncCode;
//   output reg [3:0] ALUCtl;
//   always @(ALUOp,FuncCode) case (ALUOp)
//     2'b00: ALUCtl <= 4'b0010; // add
//     2'b01: ALUCtl <= 4'b0110; // subtract
//     2'b10: case (FuncCode)
// 	     32: ALUCtl <= 4'b0010; // add
// 	     34: ALUCtl <= 4'b0110; // sub
// 	     36: ALUCtl <= 4'b0000; // and
// 	     37: ALUCtl <= 4'b0001; // or
// 	     39: ALUCtl <= 4'b1100; // nor
// 	     42: ALUCtl <= 4'b0111; // slt
//     endcase
//   endcase
// endmodule

module CPU (clock,PC,IFID_IR,IDEX_IR,WD);
  input clock;
  output [31:0] PC,IFID_IR,IDEX_IR,WD;
  
  initial begin
// Program with nop's - no hazards
// You only require one nop because we only have 3 stages instead of 5. do not need 2 nops for hazards, only one
    IMemory[0]  = 32'h2009000f;  // addi $t1, $0,  15   ($t1=15)
    IMemory[1]  = 32'h200a0007;  // addi $t2, $0,  7    ($t2= 7)
    IMemory[2]  = 32'h00000000;  // nop (required for $t1 hazard)
    IMemory[3]  = 32'h012a5824;  // and  $t3, $t1, $t2  ($t3= 7)
    IMemory[4]  = 32'h00000000;  // nop (required for $t3 hazard)
    IMemory[5]  = 32'h012b5022;  // sub  $t2, $t1, $t3  ($t2= 8)
    IMemory[6]  = 32'h00000000;  // nop (required for $t3 hazard)
    IMemory[7]  = 32'h014b5025;  // or   $t2, $t2, $t3  ($t2=15)
    IMemory[8]  = 32'h00000000;  // nop (required for $t2 hazard)
    IMemory[9]  = 32'h014b5820;  // add  $t3, $t2, $t3  ($t3=22)
    IMemory[10] = 32'h00000000;  // nop (required for $t2 hazard)
    IMemory[11] = 32'h014b4827;  // nor  $t1, $t2, $t3  ($t1=-32)
    IMemory[12] = 32'h016a482a;  // slt  $t1, $t3, $t2  ($t1= 0)
    IMemory[13] = 32'h014b482a;  // slt  $t1, $t2, $t3  ($t1= 1)
  end
/*
  initial begin 
// Program without nop's - wrong results due to data hazards
    IMemory[0] = 32'h2009000f;  // addi $t1, $0,  15   ($t1=15)
    IMemory[1] = 32'h200a0007;  // addi $t2, $0,  7    ($t2= 7)
    IMemory[2] = 32'h012a5824;  // and  $t3, $t1, $t2  ($t3= 7)
    IMemory[3] = 32'h012b5022;  // sub  $t2, $t1, $t3  ($t2= 8)
    IMemory[4] = 32'h014b5025;  // or   $t2, $t2, $t3  ($t2=15)
    IMemory[5] = 32'h014b5820;  // add  $t3, $t2, $t3  ($t3=22)
    IMemory[6] = 32'h014b4827;  // nor  $t1, $t2, $t3  ($t1=-32)
    IMemory[7] = 32'h016a482a;  // slt  $t1, $t3, $t2  ($t1= 0)
    IMemory[8] = 32'h014b482a;  // slt  $t1, $t2, $t3  ($t1= 1)
  end
*/
// Pipeline stages
//=== IF STAGE ===
   wire [31:0] NextPC;
   reg[31:0] PC, IMemory[0:1023];
//--------------------------------
   reg[31:0] IFID_IR;
//--------------------------------
   alu fetch (4'b0010,PC,4,NextPC,Unused);

//=== ID STAGE ===
   wire [6:0] Control; //this needs to become 7 bits
   wire [31:0] RD1,RD2,SignExtend,WD;
   wire [31:0] FWD_RD1,FWD_RD2; // Outputs of the forwarding muxes
   reg [31:0] IDEX_IR; // For monitoring the pipeline
   reg IDEX_RegWrite,IDEX_ALUSrc,IDEX_RegDst;
   reg [3:0]  IDEX_ALUctl;
   reg [31:0] IDEX_RD1,IDEX_RD2,IDEX_SignExt;
   reg [4:0]  IDEX_rt,IDEX_rd; 
                               
   wire [4:0] WR;
   reg_file rf (IFID_IR[25:21],IFID_IR[20:16],WR,WD,IDEX_RegWrite,RD1,RD2,clock);
   MainControl MainCtr (IFID_IR[31:26],Control); 
   assign SignExtend = {{16{IFID_IR[15]}},IFID_IR[15:0]}; 

//=== EXE STAGE ===
   wire [31:0] B,ALUOut;
//    wire [3:0] ALUctl; not needed, taking IDEX_aluctl from id stage
   alu ex (IDEX_ALUctl, IDEX_RD1, B, ALUOut, Zero);
   // ALUControl ALUCtrl(IDEX_ALUOp, IDEX_SignExt[5:0], ALUctl); // ALU control unit not needed

   //IMPLEMENT GATE LEVEL
   assign B  = (IDEX_ALUSrc) ? IDEX_SignExt: IDEX_RD2;   // ALUSrc Mux 
   //IMPLEMENT GATE LEVEL
   assign WR = (IDEX_RegDst) ? IDEX_rd: IDEX_rt;         // RegDst Mux
   assign WD = ALUOut;

// Forwarding multiplexers
   assign FWD_RD1 = (IDEX_RegWrite && WR==IFID_IR[25:21]) ? ALUOut: RD1;
   assign FWD_RD2 = (IDEX_RegWrite && WR==IFID_IR[20:16]) ? ALUOut: RD2;

   initial begin
    PC = 0;
    IFID_IR = 0; // clear pipeline register to avoid forwarding from empty pipeline
    IDEX_RegWrite = 0; 
   end

// Running the pipeline
   always @(negedge clock) begin

// Stage 1 - IF
    PC <= NextPC;
    IFID_IR <= IMemory[PC>>2];

// Stage 2 - ID
    IDEX_IR <= IFID_IR; // For monitoring the pipeline
    {IDEX_RegDst,IDEX_ALUSrc,IDEX_RegWrite,IDEX_ALUctl} <= Control; //need aluctl instead of aluop here (done)

//  No Forwarding
    IDEX_RD1 <= RD1; 
    IDEX_RD2 <= RD2;

//  Forwarding
//  IDEX_RD1 <= FWD_RD1; 
//  IDEX_RD2 <= FWD_RD2;

//  label all of this on the diggram in the IDEX stage
    IDEX_SignExt <= SignExtend;
    IDEX_rt <= IFID_IR[20:16]; //change these bits
    IDEX_rd <= IFID_IR[15:11]; //change tehse bits

// Stage 3 - EX
// No transfers needed here - on negedge WD is written into register WR
  end
endmodule

// Test module
module test ();
  reg clock;
  wire signed [31:0] PC,IFID_IR,IDEX_IR,WD;
  CPU test_cpu(clock,PC,IFID_IR,IDEX_IR,WD);
  always #1 clock = ~clock;
  initial begin
    $display ("PC  IFID_IR   IDEX_IR   WD");
    $monitor ("%2d  %h  %h  %2d",PC,IFID_IR,IDEX_IR,WD);
    clock = 1;
    #29 $finish;
  end
endmodule

/* Output
Program with nop's
---------------------------

there are now two fields for instructions
you can notice there is a jagged pattern where the IDEX
is updated with the IFID every instruction, and the IFIF
is updated by the next instruction in memory

 PC  IFID_IR   IDEX_IR   WD
 0  00000000  xxxxxxxx   x
 4  2009000f  00000000   x
 8  200a0007  2009000f  15
12  00000000  200a0007   7
16  012a5824  00000000   0
20  00000000  012a5824   7
24  012b5022  00000000   0
28  00000000  012b5022   8
32  014b5025  00000000   0
36  00000000  014b5025  15
40  014b5820  00000000   0
44  00000000  014b5820  22
48  014b4827  00000000   0
52  016a482a  014b4827  -32
56  014b482a  016a482a   0
60  xxxxxxxx  014b482a   1

Program without nop's
--------------------------
PC  IFID_IR   IDEX_IR   WD
 0  00000000  xxxxxxxx   x
 4  2009000f  00000000   x
 8  200a0007  2009000f  15
12  012a5824  200a0007   7
16  012b5022  012a5824   X
20  014b5025  012b5022   x
24  014b5820  014b5025   X
28  014b4827  014b5820   x
32  016a482a  014b4827   X
36  014b482a  016a482a   X
40  xxxxxxxx  014b482a   X
44  xxxxxxxx  xxxxxxxx   X
48  xxxxxxxx  xxxxxxxx   X
52  xxxxxxxx  xxxxxxxx   X
56  xxxxxxxx  xxxxxxxx   X
60  xxxxxxxx  xxxxxxxx   X
*/