// Behavioral model of MIPS - single cycle implementation, R-types and addi

// This is modified based off of the new diagram, new bit indexes

module reg_file (RR1,RR2,WR,WD,RegWrite,RD1,RD2,clock);
  input [1:0] RR1,RR2,WR;
  input [15:0] WD;
  input RegWrite,clock;
  output [15:0] RD1,RD2;
  reg [15:0] Regs[0:3];
  assign RD1 = Regs[RR1];
  assign RD2 = Regs[RR2];
  initial Regs[0] = 0;
  always @(negedge clock)
    if (RegWrite==1 & WR!=0) 
	Regs[WR] <= WD;
endmodule

//implement this gate level

module alu (ALUctl,A,B,ALUOut,Zero);
  input [3:0] ALUctl;
  input [15:0] A,B;
  output reg [15:0] ALUOut;
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
    endcase
  assign Zero = (ALUOut==0); // Zero is true if ALUOut is 0
endmodule

//  MainControl has be rewritten to reflect new table

module MainControl (Op,Control); 
  input [3:0] Op;
  output reg [6:0] Control;
// Control bits: RegDst,ALUSrc,RegWrite,ALUctl
  always @(Op) case (Op)
    4'b0000: Control <= 5'b10110; // Rtype
    4'b0000: Control <= 7'b101_0010; //add
    4'b0001: Control <= 7'b101_0110; //subtract
    4'b0010: Control <= 7'b101_0000; //and
    4'b0011: Control <= 7'b101_0001; //or
    4'b0100: Control <= 7'b101_1100; //nor
    4'b0101: Control <= 7'b101_1101; //nand
    4'b0110: Control <= 7'b101_0111; //slt
    4'b0111: Control <= 7'b011_0010; //addi
  endcase
endmodule

// ALUControl is not needed because the function field does not exist
// This applies to ALL DELIVERABLES

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


module multiplexer_2x1 (X, Y, Z, out);
    input X, Y, Z;
    output out;
    wire c1, c2;
    wire not_z;

    // NOT gate
    not n1 (not_z, Z);

    // AND gates
    and a1 (c1, X, not_z);
    and a2 (c2, Y, Z);

    // OR gate
    or o1 (out, c1, c2);
endmodule


module CPU (clock,PC,ALUOut,IR);
  input clock;
  output [15:0] ALUOut,IR,PC;
  reg[15:0] PC;
  reg[15:0] IMemory[0:1023];
  wire [15:0] IR,NextPC,A,B,ALUOut,RD2,SignExtend;
  wire [3:0] ALUctl;
  wire [1:0] WR; 
// Test Program
  initial begin 
    //CHANGE EVERY INSTRUCTION TO BINARY FROM HEX
    //THE FOLLOWING ADDI and AND COMMANDS ARE EXAMPLES
    //                 op rs rt    value
    IMemory[0] = 16'b0111_00_01_00001111;  // addi $t1, $0,  15   ($t1=15)
    //                 op rs rt rd empty
    IMemory[2] = 16'b0000_01_10_11_0000000;  // and  $3, $1, $2  ($t3=7)
    // 32'h200a0007
    IMemory[1] = 16'b0111_00_10_00000111;  // addi $t2, $0,  7    ($t2=7)
    // 32'h012b5022
    IMemory[3] = 16'b0001_01_11_10_000000;  // sub  $t2, $t1, $t3  ($t2=8)
    // 32'h014b5025
    IMemory[4] = 16'b0011_10_11_10_000000;  // or   $t2, $t2, $t3  ($t2=15)
    // 32'h014b5820
    IMemory[5] = 16'b0000_10_11_11_000000;  // add  $t3, $t2, $t3  ($t3=22)
    // 32'h014b4827
    IMemory[6] = 16'b0100_10_11_01_000000;  // nor  $t1, $t2, $t3  ($t1=-32)
    // 32'h016a482a
    IMemory[7] = 16'b0110_11_10_01_000000;  // slt  $t1, $t3, $t2  ($t1=0)
    // 32'h014b482a
    IMemory[8] = 16'b0110_10_11_01_000000;  // slt  $t1, $t2, $t3  ($t1=1)
  end
  initial PC = 0;
  assign IR = IMemory[PC>>1];

  //THESE MULTIPLEXERS NEEDS TO BE GATELEVEL
  //assign WR = (RegDst) ? IR[7:6]: IR[9:8]; // RegDst Mux
  //THIS IS 2 INSTANCES of 2x1 MULTIPLEXER
  
  multiplexer_2x1 muxIR1 (IR[9], IR[7], RegDst, WR[1]);
  multiplexer_2x1 muxIR2 (IR[8], IR[6], RegDst, WR[0]);
  
  //THS IS 16 INSTANCES of 2x1 MULTIPLEXER FOR 16 BITS SIGN EXTENSION
  //assign B  = (ALUSrc) ? SignExtend: RD2; // ALUSrc Mux 
  
  multiplexer_2x1 mux0 (RD2[0], SignExtend[0], ALUSrc, B[0]);
  multiplexer_2x1 mux1 (RD2[1], SignExtend[1], ALUSrc, B[1]);
  multiplexer_2x1 mux2 (RD2[2], SignExtend[2], ALUSrc, B[2]);
  multiplexer_2x1 mux3 (RD2[3], SignExtend[3], ALUSrc, B[3]);
  multiplexer_2x1 mux4 (RD2[4], SignExtend[4], ALUSrc, B[4]);
  multiplexer_2x1 mux5 (RD2[5], SignExtend[5], ALUSrc, B[5]);
  multiplexer_2x1 mux6 (RD2[6], SignExtend[6], ALUSrc, B[6]);
  multiplexer_2x1 mux7 (RD2[7], SignExtend[7], ALUSrc, B[7]);
  multiplexer_2x1 mux8 (RD2[8], SignExtend[8], ALUSrc, B[8]);
  multiplexer_2x1 mux9 (RD2[9], SignExtend[9], ALUSrc, B[9]);
  multiplexer_2x1 mux10 (RD2[10], SignExtend[10], ALUSrc, B[10]);
  multiplexer_2x1 mux11 (RD2[11], SignExtend[11], ALUSrc, B[11]);
  multiplexer_2x1 mux12 (RD2[12], SignExtend[12], ALUSrc, B[12]);
  multiplexer_2x1 mux13 (RD2[13], SignExtend[13], ALUSrc, B[13]);
  multiplexer_2x1 mux14 (RD2[14], SignExtend[14], ALUSrc, B[14]);
  multiplexer_2x1 mux15 (RD2[15], SignExtend[15], ALUSrc, B[15]);
  
  assign SignExtend = {{8{IR[7]}},IR[7:0]}; // sign extension unit
  reg_file rf (IR[11:10],IR[9:8],WR,ALUOut,RegWrite,A,RD2,clock);
  alu fetch (4'b0010,PC,16'd2,NextPC,Unused);
  alu ex (ALUctl, A, B, ALUOut, Zero);
  MainControl MainCtr (IR[15:12],{RegDst,ALUSrc,RegWrite,ALUctl}); 
  //ALUControl ALUCtrl(ALUOp, IR[5:0], ALUctl); // ALUControl is not needed, we just use the op
  always @(negedge clock) begin 
    PC <= NextPC;
  end
endmodule

// Test module
module test ();
  reg clock;
  wire signed [15:0] WD,IR,PC;
  CPU test_cpu(clock,PC,WD,IR);
  always #1 clock = ~clock;
  initial begin
    $display ("Clock PC   IR                                 WD");
    $monitor ("%b     %2d   %b  %3d (%b)",clock,PC,IR,WD,WD);
    clock = 1;
    #16 $finish;
  end
endmodule

/* Output
Clock PC   IR                                 WD
1      0   00100000000010010000000000001111   15 (00000000000000000000000000001111)
0      4   00100000000010100000000000000111    7 (00000000000000000000000000000111)
1      4   00100000000010100000000000000111    7 (00000000000000000000000000000111)
0      8   00000001001010100101100000100100    7 (00000000000000000000000000000111)
1      8   00000001001010100101100000100100    7 (00000000000000000000000000000111)
0     12   00000001001010110101000000100010    8 (00000000000000000000000000001000)
1     12   00000001001010110101000000100010    8 (00000000000000000000000000001000)
0     16   00000001010010110101000000100101   15 (00000000000000000000000000001111)
1     16   00000001010010110101000000100101   15 (00000000000000000000000000001111)
0     20   00000001010010110101100000100000   22 (00000000000000000000000000010110)
1     20   00000001010010110101100000100000   22 (00000000000000000000000000010110)
0     24   00000001010010110100100000100111  -32 (11111111111111111111111111100000)
1     24   00000001010010110100100000100111  -32 (11111111111111111111111111100000)
0     28   00000001011010100100100000101010    0 (00000000000000000000000000000000)
1     28   00000001011010100100100000101010    0 (00000000000000000000000000000000)
0     32   00000001010010110100100000101010    1 (00000000000000000000000000000001)
1     32   00000001010010110100100000101010    1 (00000000000000000000000000000001)
*/