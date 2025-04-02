//taking the behavioral model of the CPU and adding the changed necessary for 
//second deliverable (branching and immediate instructions)

//obviously change everything from 32 bits to 16 bits, did in a few places but not all




// Behavioral model of MIPS - single cycle implementation
/*
module reg_file (RR1,RR2,WR,WD,RegWrite,RD1,RD2,clock); //this is fine from proj1
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
*/

// Behavioral model of a 16-bit MIPS single-cycle CPU, supporting R-type and immediate arithmetic.
module reg_file (RR1, RR2, WR, WD, RegWrite, RD1, RD2, clock);
    input [1:0] RR1, RR2, WR; // Read register 1, Read register 2, Write register
    input [15:0] WD;          // Write data
    input RegWrite, clock;   // Register write enable, clock signal
    output [15:0] RD1, RD2;  // Read data 1, Read data 2
    reg [15:0] Regs[0:3];     // Register file (4 registers, 16 bits each)

    assign RD1 = Regs[RR1];   // Read data 1 from register file
    assign RD2 = Regs[RR2];   // Read data 2 from register file

    initial Regs[0] = 0;      // Initialize register 0 to 0

    always @(negedge clock)
        if (RegWrite == 1 && WR != 0) // Write to register file on negative clock edge if RegWrite is enabled and WR is not 0
            Regs[WR] <= WD;
endmodule

module alu (ALUctl,A,B,ALUOut,Zero); //this is fine from proj2
  input [3:0] ALUctl;
  input [15:0] A,B;
  output reg [15:0] ALUOut;
  output Zero, Overflow;
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

module MainControl (Op,Control); 
  input [3:0] Op; //change this from 6 to 4 bits
  output reg [7:0] Control; //change this from 8 to 11 bits
// RegDst,ALUSrc,MemtoReg,RegWrite,MemWrite,Beq,Bne,ALUCtl //changed branch to beq and bne, and ALUOp to AluCtl
  always @(Op) case (Op)
    //get the opcodes from the table on the semester project page
    4'b0000: Control <= 11'b10010_00_0010; // Add
    //include all other R types from table
    4'b0001: Control <= 11'b10001_00_0010; // Sub
    4'b0010: Control <= 11'b10001_00_0010; // And
    4'b0011: Control <= 11'b10001_00_0010; // Or
    4'b0100: Control <= 11'b10001_00_0010; // Nor
    4'b0101: Control <= 11'b10001_00_0010; // Slt
    
    4'b0111: Control <= 11'b01010100; // ADDI
    4'b1000: Control <= 11'b01110_00_0010; // LW    
    4'b1001: Control <= 11'b01001_00_0010; // SW  
    4'b1010: Control <= 11'b00000_10_0110; // BEQ 
    4'b1011: Control <= 11'b00000_01_0110; // BNE 
  endcase
endmodule

//ALUControl NOT NEEDED


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

module CPU (clock,WD,IR,PC);

  input clock;
  output [15:0] WD,IR,PC;
  reg[15:0] PC, IMemory[0:1023], DMemory[0:1023];
  wire [15:0] IR,SignExtend,NextPC,RD2,A,B,ALUOut,PCplus4,Target;
  wire [1:0] WR;
  wire [3:0] ALUctl;
//   wire [1:0] ALUOp;
  initial begin 
 // Program: swap memory cells and compute absolute value

 //change everything to 16 bit binary
    //IMemory[0] = 32'h8c090000;  // lw $1, 0($0) 
    IMemory[0] = 16'b1000_00_01_00000000;  // lw $1, 0($0)
    //IMemory[1] = 32'h8c0a0004;  // lw $2, 2($0)
    IMemory[1] = 16'b1000_00_10_00000010;  // lw $2, 2($0)
    //IMemory[2] = 32'h012a582a;  // slt $t3, $1, $2
    IMemory[2] = 16'b0110_01_10_11_000000;;
    //IMemory[3] = 32'h11600002;  // beq $3, $0, IMemory[6] to test, include bne instead of beq, the result will instead be -2
    IMemory[3] = 16'b1010_11_00_01100000;  // beq $3, $0, IMemory[6]
    //IMemory[4] = 32'hac090004;  // sw $1, 2($0) 
    IMemory[4] = 16'b1001_00_01_00000010;  // sw $1, 2($0)
    //IMemory[5] = 32'hac0a0000;  // sw $2, 0($0) 
    IMemory[5] = 16'b1001_00_10_00000000;  // sw $1, 2($0)
    //IMemory[6] = 32'h8c090000;  // lw $1, 0($0) 
    IMemory[6] = 16'b1000_00_01_00000000;  // lw $1, 0($0)
    //IMemory[7] = 32'h8c0a0004;  // lw $2, 2($0)
    IMemory[7] = 16'b1000_00_10_00000010;  // lw $2, 2($0) 
    //IMemory[8] = 32'h014a5027;  // nor $2, $2, $2 (sub $3, $1, $2 in two's complement)
    IMemory[8] = 16'b0100_01_10_11_000000; // nor $2, $2, $2
    //IMemory[9] = 32'h214a0001;  // addi $2, $2, 1 
    IMemory[9] = 16'b0111_10_10_00000001;  // addi $2, $2, 1
    //IMemory[10] = 32'h012a5820;  // add $3, $1, $2 
    IMemory[10] = 16'b0000_01_10_11_000000; // add $3, $1, $2
 // Data
    DMemory [0] = 16'd5; // swap the cells and see how the simulation output changes
    DMemory [1] = 16'd7;
  end
  initial PC = 0;
  assign IR = IMemory[PC>>1]; //change the shift to 1 not 2
  assign SignExtend = {{16{IR[15]}},IR[15:0]}; // sign extension
  reg_file rf (IR[11:10],IR[9:8],WR,WD,RegWrite,A,RD2,clock);
  
  alu fetch (4'b0010,PC,16'b0000000000000100,PCplus4,Unused1);
  alu ex (ALUctl, A, B, ALUOut, Zero);

  alu branch (4'b0010,SignExtend<<1,PCplus4,Target,Unused2); //change sign extend from 2 to 1
  MainControl MainCtr (IR[15:12],{RegDst,ALUSrc,MemtoReg,RegWrite,MemWrite,Beq,Bne,ALUCtl}); //changed parameters
//   ALUControl ALUCtrl(ALUOp, IR[5:0], ALUctl); // ALU control unit
  assign WR = (RegDst) ? IR[15:11]: IR[20:16]; // RegDst Mux
  assign WD = (MemtoReg) ? DMemory[ALUOut>>1]: ALUOut; // MemtoReg Mux (change shift from 2 to 1)
  assign B  = (ALUSrc) ? SignExtend: RD2; // ALUSrc Mux 

  //this branch mux is the branch control unit, must be implemented gate level
  assign NextPC = (Beq && Zero || Bne && Zero) ? Target: PCplus4; // Branch Mux

  always @(negedge clock) begin 
    PC <= NextPC;
    // ** does this need to be >>1? **
    if (MemWrite) DMemory[ALUOut>>2] <= RD2;
  end
endmodule

// Test module
module test ();
  reg clock;
  wire signed [15:0] WD,IR,PC;
  CPU test_cpu(clock,WD,IR,PC);
  always #1 clock = ~clock;
  initial begin
    $display ("PC  IR                                WD");
    $monitor ("%2d  %b %2d (%b)",PC,IR,WD,WD);
    clock = 1;
    #20 $finish;
  end
endmodule

/* Output
PC  IR                                WD
 0  10001100000010010000000000000000  5 (00000000000000000000000000000101)
 4  10001100000010100000000000000100  7 (00000000000000000000000000000111)
 8  00000001001010100101100000101010  1 (00000000000000000000000000000001)
12  00010001011000000000000000000010  1 (00000000000000000000000000000001)
16  10101100000010010000000000000100  4 (00000000000000000000000000000100)
20  10101100000010100000000000000000  0 (00000000000000000000000000000000)
24  10001100000010010000000000000000  7 (00000000000000000000000000000111)
28  10001100000010100000000000000100  5 (00000000000000000000000000000101)
32  00000001010010100101000000100111 -6 (11111111111111111111111111111010)
36  00100001010010100000000000000001 -5 (11111111111111111111111111111011)
40  00000001001010100101100000100000  2 (00000000000000000000000000000010) (-2 if you use bne)
*/