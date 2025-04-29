// Behavioral model of MIPS - pipelined implementation

// FOR THE FINAL SUBMISSION:
// PROVIDE TEST CASES USING:
// NOPS, NO NOPS
// BEQ, BNE BY SWAPPING MEMORY CELLS


module reg_file (RR1, RR2, WR, WD, RegWrite, RD1, RD2, clock);
    input [1:0] RR1, RR2, WR;       // Read register 1, Read register 2, Write register
    input [15:0] WD;                // Write data
    input RegWrite, clock;         // Register write enable, clock signal
    output [15:0] RD1, RD2;        // Read data outputs
    reg [15:0] Regs[0:3];          // Register file (4 registers)

    assign RD1 = Regs[RR1];        // Read from RR1
    assign RD2 = Regs[RR2];        // Read from RR2

    initial Regs[0] = 0;           // Register 0 is always 0

    always @(negedge clock)
        if (RegWrite == 1 && WR != 0)
            Regs[WR] <= WD;
endmodule

// Computes the sum and carry of two input bits (half-adder).
module halfadder (S, C, x, y);
    input x, y;
    output S, C;

    xor (S, x, y); // Sum = x XOR y
    and (C, x, y); // Carry = x AND y
endmodule

// Computes the sum and carry of three input bits (full-adder).
module full_adder (x, y, z, C, S);
    input x, y, z;
    output S, C;
    wire S1, D1, D2;

    halfadder HA1 (S1, D1, x, y),
              HA2 (S, D2, S1, z);
    or g1 (C, D2, D1);
endmodule

// 2-to-1 multiplexer.
module mux2x1 (x, y, sel, out);
    input x, y, sel;
    output out;
    wire a, b, c;

    not g1 (a, sel);
    and g2 (b, x, a),
        g3 (c, y, sel);
    or  g4 (out, b, c);
endmodule

// 4-to-1 multiplexer using 3 2-to-1 muxes.
module mux4x1 (w, x, y, z, ctrl, out);
    input w, x, y, z;
    input [1:0] ctrl;
    output out;
    wire mux1out, mux2out;

    mux2x1 mux1 (w, x, ctrl[0], mux1out),
           mux2 (y, z, ctrl[0], mux2out),
           mux3 (mux1out, mux2out, ctrl[1], out);
endmodule

// 1-bit ALU
module ALU1 (a, b, ainvert, binvert, op, less, carryin, carryout, result);
    input a, b, less, carryin, ainvert, binvert;
    input [1:0] op;
    output carryout, result;
    wire nota, notb, c, d, e, f, sum;

    not na (nota, a), nb (notb, b);
    mux2x1 muxa (a, nota, ainvert, c),
           muxb (b, notb, binvert, d);

    and ag1 (e, c, d);
    or  og1 (f, c, d);
    full_adder fa (c, d, carryin, carryout, sum);
    mux4x1 muxop (e, f, sum, less, op, result);
endmodule

// Most significant bit ALU with "set" output
module ALUmsb (a, b, ainvert, binvert, op, less, carryin, carryout, result, set);
    input a, b, less, carryin, ainvert, binvert;
    input [1:0] op;
    output carryout, result, set;
    wire nota, notb, c, d, f, g;

    not na (nota, a), nb (notb, b);
    mux2x1 muxa (a, nota, ainvert, c),
           muxb (b, notb, binvert, d);

    and ag2 (f, c, d);
    or  og2 (g, c, d);
    full_adder fa (c, d, carryin, carryout, set);
    mux4x1 muxop (f, g, set, less, op, result);
endmodule

// 16-bit ALU made from 15 ALU1s and 1 ALUmsb
module alu (op, a, b, ALUout, zero);
    input [3:0] op;
    input [15:0] a, b;
    output [15:0] ALUout;
    output zero;

    wire c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,set;

    ALU1 alu0 (a[0], b[0], op[3], op[2], op[1:0], set, op[2], c1, ALUout[0]),
         alu1 (a[1], b[1], op[3], op[2], op[1:0], 1'b0, c1, c2, ALUout[1]),
         alu2 (a[2], b[2], op[3], op[2], op[1:0], 1'b0, c2, c3, ALUout[2]),
         alu3 (a[3], b[3], op[3], op[2], op[1:0], 1'b0, c3, c4, ALUout[3]),
         alu4 (a[4], b[4], op[3], op[2], op[1:0], 1'b0, c4, c5, ALUout[4]),
         alu5 (a[5], b[5], op[3], op[2], op[1:0], 1'b0, c5, c6, ALUout[5]),
         alu6 (a[6], b[6], op[3], op[2], op[1:0], 1'b0, c6, c7, ALUout[6]),
         alu7 (a[7], b[7], op[3], op[2], op[1:0], 1'b0, c7, c8, ALUout[7]),
         alu8 (a[8], b[8], op[3], op[2], op[1:0], 1'b0, c8, c9, ALUout[8]),
         alu9 (a[9], b[9], op[3], op[2], op[1:0], 1'b0, c9, c10, ALUout[9]),
         alu10(a[10], b[10], op[3], op[2], op[1:0], 1'b0, c10, c11, ALUout[10]),
         alu11(a[11], b[11], op[3], op[2], op[1:0], 1'b0, c11, c12, ALUout[11]),
         alu12(a[12], b[12], op[3], op[2], op[1:0], 1'b0, c12, c13, ALUout[12]),
         alu13(a[13], b[13], op[3], op[2], op[1:0], 1'b0, c13, c14, ALUout[13]),
         alu14(a[14], b[14], op[3], op[2], op[1:0], 1'b0, c14, c15, ALUout[14]);

    ALUmsb alu15 (a[15], b[15], op[3], op[2], op[1:0], 1'b0, c14, c15, ALUout[15], set);

    nor nor1(zero, ALUout[0], ALUout[1], ALUout[2], ALUout[3], ALUout[4],
                   ALUout[5], ALUout[6], ALUout[7], ALUout[8], ALUout[9],
                   ALUout[10], ALUout[11], ALUout[12], ALUout[13], ALUout[14],
                   ALUout[15]);
endmodule

// Selects between two 2-bit inputs (I0 and I1) based on control signal Sel. 
module mux2bit2x1 (I0, I1, Sel, Out);
    input [1:0] I0,I1; 
    input Sel; 
    output [1:0] Out; 
    not g1(a,Sel), 
        g2(b,a); 
    
    and g3(c,a,I0[0]), 
        g4(d,a,I0[1]), 
        g7(g,b,I1[0]), 
        g8(h,b,I1[1]); 
    
    or g11(Out[0],c,g), 
       g12(Out[1],d,h); 
endmodule

// Selects between two 16-bit inputs (I0 and I1) based on control signal Sel. 
module mux16bit2x1 (I0, I1, Sel, Out);
    input [15:0] I0,I1; 
    input Sel; 
    output [15:0] Out;
    wire sel_invert;
    
    not g1(sel_invert,Sel);
    
    mux2x1 mux0(I0[0],I1[0],Sel,Out[0]),
          mux1(I0[1],I1[1],Sel,Out[1]),
          mux2(I0[2],I1[2],Sel,Out[2]),
          mux3(I0[3],I1[3],Sel,Out[3]),
          mux4(I0[4],I1[4],Sel,Out[4]),
          mux5(I0[5],I1[5],Sel,Out[5]),
          mux6(I0[6],I1[6],Sel,Out[6]),
          mux7(I0[7],I1[7],Sel,Out[7]),
          mux8(I0[8],I1[8],Sel,Out[8]),
          mux9(I0[9],I1[9],Sel,Out[9]),
          mux10(I0[10],I1[10],Sel,Out[10]),
          mux11(I0[11],I1[11],Sel,Out[11]),
          mux12(I0[12],I1[12],Sel,Out[12]),
          mux13(I0[13],I1[13],Sel,Out[13]),
          mux14(I0[14],I1[14],Sel,Out[14]),
          mux15(I0[15],I1[15],Sel,Out[15]);
endmodule
//use the control from project 2 here, but you need to change the index of the inputs (RegDst -> IDEX_RegDst, etc.)

module MainControl (Op,Control); 
  input [3:0] Op;
  output reg [10:0] Control;
// IDEX_RegDst,IDEX_ALUSrc,IDEX_MemtoReg,IDEX_RegWrite,IDEX_MemWrite,IDEX_Beq,IDEX_Bne,IDEX_ALUCtl

  //no changes from proj 2 on this (already changed)
  always @(Op) case (Op)
        4'b0000: Control <= 11'b10010_0_0_0010; // ADD
        4'b0001: Control <= 11'b10010_0_0_0110; // SUB
        4'b0010: Control <= 11'b10010_0_0_0000; // AND
        4'b0011: Control <= 11'b10010_0_0_0001; // OR
        4'b0100: Control <= 11'b10010_0_0_1100; // NOR
        4'b0101: Control <= 11'b10010_0_0_1101; // NAND
        4'b0110: Control <= 11'b10010_0_0_0111; // SLT

        4'b0111: Control <= 11'b01010_0_0_0010; // ADDI
        4'b1000: Control <= 11'b01110_0_0_0010; // LW    
        4'b1001: Control <= 11'b01001_0_0_0010; // SW    
        4'b1010: Control <= 11'b00000_1_0_0110; // BEQ   
        4'b1011: Control <= 11'b00000_0_1_0110; // BNE
  endcase
endmodule

module branchmux(Bne,Beq,Zero,Target,PCplus4,NextPC);
    input Beq,Bne,Zero;
    input [15:0] Target,PCplus4;
    output [15:0] NextPC;
    wire Out;
    
    mux2x1 branch(Bne,Beq,Zero,Out);
    mux16bit2x1 nextpc(PCplus4,Target,Out,NextPC);
endmodule

module CPU (clock,PC,IFID_IR,IDEX_IR,EXMEM_IR,MEMWB_IR,WD);
  input clock;
  output [15:0] PC,IFID_IR,IDEX_IR,EXMEM_IR,MEMWB_IR,WD;

  initial begin 
// Program: swap memory cells (if needed) and compute absolute value |5-7|=2
  IMemory[0] = 16'b1000_00_01_00000000;  // lw $t1, 0($0) 
  IMemory[1] = 16'b1000_00_10_00000010;  // lw $t2, 4($0)
  IMemory[2] = 16'b0000000000000000;     // nop
  IMemory[3] = 16'b0000000000000000;     // nop
  IMemory[4] = 16'b0000000000000000;     // nop
  IMemory[5] = 16'b0110_01_10_11_000000; // slt $t3, $t1, $t2
  IMemory[6] = 16'b0000000000000000;     // nop
  IMemory[7] = 16'b0000000000000000;     // nop
  IMemory[8] = 16'b0000000000000000;    // nop
  IMemory[9] = 16'b1011_11_00_00000101;  // bne $t3, $0, IMemory[6]
  //IMemory[9] = 16'b1010_11_00_00000101;  // beq $t3, $0, IMemory[6]
  IMemory[10]= 16'b0000000000000000;    // nop
  IMemory[11]= 16'b0000000000000000;    // nop
  IMemory[12]= 16'b0000000000000000;    // nop
  IMemory[13]= 16'b1001_00_01_00000010;  // sw $t1, 4($0) 
  IMemory[14]= 16'b1001_00_10_00000000;  // sw $t2, 0($0)
  IMemory[15]= 16'b0000000000000000;    // nop
  IMemory[16]= 16'b0000000000000000;     // nop
  IMemory[17]= 16'b0000000000000000;     // nop
  IMemory[18]= 16'b1000_00_01_00000000;  // lw $t1, 0($0) 
  IMemory[19]= 16'b1000_00_10_00000010;  // lw $t2, 4($0)
  IMemory[20]= 16'b0000000000000000;     // nop
  IMemory[21]= 16'b0000000000000000;     // nop
  IMemory[22]= 16'b0000000000000000;     // nop
  IMemory[23]= 16'b0100_10_10_10_000000; // nor $t2, $t2, $t2 (sub $3, $1, $2 in two's complement)
  IMemory[24]= 16'b0000000000000000;     // nop
  IMemory[25]= 16'b0000000000000000;     // nop
  IMemory[26]= 16'b0000000000000000;     // nop
  IMemory[27]= 16'b0111_10_10_00000001;  // addi $t2, $t2, 1 
  IMemory[28]= 16'b0000000000000000;     // nop
  IMemory[29]= 16'b0000000000000000;     // nop
  IMemory[30]= 16'b0000000000000000;     // nop
  IMemory[31]= 16'b0000_01_10_11_000000; // add $t3, $t1, $t2 
// Data
  DMemory[1] = 16'd5; // switch the cells and see how the simulation output changes
  DMemory[0] = 16'd7; // (beq is taken if DMemory[0]=7; DMemory[1]=5, not taken otherwise)
  end
  
//   initial begin 
// // Program: swap memory cells (if needed) and compute absolute value |5-7|=2
//   IMemory[0] = 16'b1000_00_01_00000000;  // lw $t1, 0($0) 
//   IMemory[1] = 16'b1000_00_10_00000010;  // lw $t2, 4($0)
//   IMemory[5] = 16'b0110_01_10_11_000000; // slt $t3, $t1, $t2
//   IMemory[9] = 16'b1011_11_00_00000101;  // bne $t3, $0, IMemory[6]
//   IMemory[9] = 16'b1010_11_00_00000101;  // beq $t3, $0, IMemory[6]
//   IMemory[13]= 16'b1001_00_01_00000010;  // sw $t1, 4($0) 
//   IMemory[14]= 16'b1001_00_10_00000000;  // sw $t2, 0($0)
//   IMemory[18]= 16'b1000_00_01_00000000;  // lw $t1, 0($0) 
//   IMemory[19]= 16'b1000_00_10_00000010;  // lw $t2, 4($0)
//   IMemory[23]= 16'b0100_10_10_10_000000; // nor $t2, $t2, $t2 (sub $3, $1, $2 in two's complement)
//   IMemory[27]= 16'b0111_10_10_00000001;  // addi $t2, $t2, 1 
//   IMemory[31]= 16'b0000_01_10_11_000000; // add $t3, $t1, $t2 
// // Data
//   DMemory[0] = 16'd5; // switch the cells and see how the simulation output changes
//   DMemory[1] = 16'd7; // (beq is taken if DMemory[0]=7; DMemory[1]=5, not taken otherwise)
//   end
  

// Pipeline 
// IF 

    //change the pc incrementing to 16 bit obviously
   wire [15:0] PCplus4, NextPC;
   reg[15:0] PC, IMemory[0:1023], IFID_IR, IFID_PCplus4, EXMEM_Target;
   //here, you must put the branch control unit and the multiplexer, so that NextPC operates correctly (this is in proj2
   alu fetch (4'b0010, PC, 16'b10, PCplus4, Unused1);
   //these will be the inputs and the logic of the branch control unit: EXMEM_Beq && EXMEM_Zero||EXMEM_Bne && ~EXMEM_Zero
   branchmux NextPCmux( EXMEM_Bne,EXMEM_Beq,EXMEM_Zero,EXMEM_Target,PCplus4,NextPC);
  //  assign NextPC = (EXMEM_Beq && EXMEM_Zero||EXMEM_Bne && ~EXMEM_Zero) ? EXMEM_Target: PCplus4;
// ID
   wire [10:0] Control;
   reg IDEX_RegWrite,IDEX_MemtoReg,
       IDEX_Beq, IDEX_Bne,  IDEX_MemWrite,
       IDEX_ALUSrc,  IDEX_RegDst;
  //  reg [3:0]  IDEX_ALUCtl; //this is correctly changed
   wire [15:0] RD1,RD2,SignExtend, WD;
   reg [15:0] IDEX_PCplus4,IDEX_RD1,IDEX_RD2,IDEX_SignExt,IDEXE_IR;
   reg [15:0] IDEX_IR; // For monitoring the pipeline
   reg [1:0]  IDEX_rt,IDEX_rd; //this is correctly changed
   reg MEMWB_RegWrite; // part of MEM stage, but declared here before use (to avoid error)
   reg [1:0] MEMWB_rd; // part of MEM stage, but declared here before use (to avoid error)
   reg_file rf (IFID_IR[11:10],IFID_IR[9:8],MEMWB_rd,WD,MEMWB_RegWrite,RD1,RD2,clock);
   MainControl MainCtr (IFID_IR[15:12],Control);  //this is correctly changed
   assign SignExtend = {{8{IFID_IR[7]}},IFID_IR[7:0]}; 
// EXE
   reg EXMEM_RegWrite,EXMEM_MemtoReg,
       EXMEM_Bne, EXMEM_Beq, EXMEM_MemWrite;
   wire [15:0] Target;
   reg EXMEM_Zero;
   reg [15:0] EXMEM_ALUOut,EXMEM_RD2;
   reg [15:0] EXMEM_IR; // For monitoring the pipeline
   reg [4:0] EXMEM_rd; //this is correctly changed
   wire [15:0] B,ALUOut;
   reg [3:0] IDEX_ALUOp;
   
   wire [1:0] WR; //this is correctly changed
   alu branch (4'b0010,IDEX_SignExt<<1,IDEX_PCplus4,Target,Unused2);
   alu ex (IDEX_ALUOp, IDEX_RD1, B, ALUOut, Zero); //changed correctly
   mux16bit2x1 muxb (IDEX_RD2, IDEX_SignExt, IDEX_ALUSrc, B); // ALUSrc Mux
   mux2bit2x1 muxwr (IDEX_rt, IDEX_rd, IDEX_RegDst, WR); // RegDst Mux

//    ALUControl ALUCtrl(IDEX_ALUOp, IDEX_SignExt[5:0], ALUctl); // ALU control unit
  //  assign B  = (IDEX_ALUSrc) ? IDEX_SignExt: IDEX_RD2;        // ALUSrc Mux 
  //  assign WR = (IDEX_RegDst) ? IDEX_rd: IDEX_rt;              // RegDst Mux
// MEM
   reg MEMWB_MemtoReg;
   reg [15:0] DMemory[0:1023],MEMWB_MemOut,MEMWB_ALUOut;
   reg [15:0] MEMWB_IR; // For monitoring the pipeline
   wire [15:0] MemOut;
   assign MemOut = DMemory[EXMEM_ALUOut>>1];
   always @(negedge clock) if (EXMEM_MemWrite) DMemory[EXMEM_ALUOut>>1] <= EXMEM_RD2;
// WB
   mux16bit2x1 muxWD(MEMWB_ALUOut,MEMWB_MemOut,MEMWB_MemtoReg,WD);

   initial begin
    PC = 0;
// Initialize pipeline registers
    IDEX_RegWrite=0;IDEX_MemtoReg=0;IDEX_Bne=0; IDEX_Beq=0;IDEX_MemWrite=0;IDEX_ALUSrc=0;IDEX_RegDst=0;IDEX_ALUOp=0;
    IFID_IR=0;
    EXMEM_RegWrite=0;EXMEM_MemtoReg=0;EXMEM_Bne=0; EXMEM_Beq=0;EXMEM_MemWrite=0;
    EXMEM_Target=0;
    MEMWB_RegWrite=0;MEMWB_MemtoReg=0;
   end

// Running the pipeline
   always @(negedge clock) begin 
// IF
    PC <= NextPC;
    IFID_PCplus4 <= PCplus4;
    IFID_IR <= IMemory[PC>>1];
// ID

    IDEX_IR <= IFID_IR; // For monitoring the pipeline
    {IDEX_RegDst,IDEX_ALUSrc,IDEX_MemtoReg,IDEX_RegWrite,IDEX_MemWrite,IDEX_Beq,IDEX_Bne,IDEX_ALUOp} <= Control;   
    IDEX_PCplus4 <= IFID_PCplus4;
    IDEX_RD1 <= RD1; 
    IDEX_RD2 <= RD2;
    IDEX_SignExt <= SignExtend;
    IDEX_rt <= IFID_IR[9:8];
    IDEX_rd <= IFID_IR[7:6];
// EXE
    EXMEM_IR <= IDEX_IR; // For monitoring the pipeline
    EXMEM_RegWrite <= IDEX_RegWrite;
    EXMEM_MemtoReg <= IDEX_MemtoReg;
    EXMEM_Beq   <= IDEX_Beq;
    EXMEM_Bne   <= IDEX_Bne;
    EXMEM_MemWrite <= IDEX_MemWrite;
    EXMEM_Target <= Target;
    EXMEM_Zero <= Zero;
    EXMEM_ALUOut <= ALUOut;
    EXMEM_RD2 <= IDEX_RD2;
    EXMEM_rd <= WR;
// MEM
    MEMWB_IR <= EXMEM_IR; // For monitoring the pipeline
    MEMWB_RegWrite <= EXMEM_RegWrite;
    MEMWB_MemtoReg <= EXMEM_MemtoReg;
    MEMWB_MemOut <= MemOut;
    MEMWB_ALUOut <= EXMEM_ALUOut;
    MEMWB_rd <= EXMEM_rd;
// WB
// Register write happens on neg edge of the clock (if MEMWB_RegWrite is asserted)
  end
endmodule

// Test module
module test ();
  reg clock;
  wire signed [15:0] PC,IFID_IR,IDEX_IR,EXMEM_IR,MEMWB_IR,WD;
  CPU test_cpu(clock,PC,IFID_IR,IDEX_IR,EXMEM_IR,MEMWB_IR,WD);
  always #1 clock = ~clock;
  initial begin
    $display ("PC   IFID_IR  IDEX_IR  EXMEM_IR MEMWB_IR  WD");
    $monitor ("%3d  %h %h %h %h %2d",PC,IFID_IR,IDEX_IR,EXMEM_IR,MEMWB_IR,WD);
    clock = 1;
    #71 $finish;
  end
endmodule

//PRINT THESE RESULTS IN BINARY NOT HEX

/* Output:
PC   IFID_IR  IDEX_IR  EXMEM_IR MEMWB_IR  WD
  0  00000000 xxxxxxxx xxxxxxxx xxxxxxxx  x
  4  8c090000 00000000 xxxxxxxx xxxxxxxx  x
  8  8c0a0004 8c090000 00000000 xxxxxxxx  x
 12  00000000 8c0a0004 8c090000 00000000  0
 16  00000000 00000000 8c0a0004 8c090000  5
 20  00000000 00000000 00000000 8c0a0004  7
 24  012a582a 00000000 00000000 00000000  0
 28  00000000 012a582a 00000000 00000000  0
 32  00000000 00000000 012a582a 00000000  0
 36  00000000 00000000 00000000 012a582a  1
 40  11600005 00000000 00000000 00000000  0
 44  00000000 11600005 00000000 00000000  0
 48  00000000 00000000 11600005 00000000  0
 52  00000000 00000000 00000000 11600005  1
 56  ac090004 00000000 00000000 00000000  0
 60  ac0a0000 ac090004 00000000 00000000  0
 64  00000000 ac0a0000 ac090004 00000000  0
 68  00000000 00000000 ac0a0000 ac090004  4
 72  00000000 00000000 00000000 ac0a0000  0
 76  8c090000 00000000 00000000 00000000  0
 80  8c0a0004 8c090000 00000000 00000000  0
 84  00000000 8c0a0004 8c090000 00000000  0
 88  00000000 00000000 8c0a0004 8c090000  7
 92  00000000 00000000 00000000 8c0a0004  5
 96  014a5027 00000000 00000000 00000000  0
100  00000000 014a5027 00000000 00000000  0
104  00000000 00000000 014a5027 00000000  0
108  00000000 00000000 00000000 014a5027 -6
112  214a0001 00000000 00000000 00000000 -1
116  00000000 214a0001 00000000 00000000 -1
120  00000000 00000000 214a0001 00000000 -1
124  00000000 00000000 00000000 214a0001 -5
128  012a5820 00000000 00000000 00000000  0
132  xxxxxxxx 012a5820 00000000 00000000  0
136  xxxxxxxx xxxxxxxx 012a5820 00000000  0
140  xxxxxxxx xxxxxxxx xxxxxxxx 012a5820  2
*/