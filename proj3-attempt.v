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
    halfadder HA1 (S1, D1, x, y), // Half-adder 1
              HA2 (S, D2, S1, z); // Half-adder 2

    or g1 (C, D2, D1); // Carry = Carry1 OR Carry2
endmodule

// 2-to-1 multiplexer.
module mux2x1 (x, y, z, out);
    input x, y, z; // Inputs x, y, select signal z
    output out;
    wire a, b, c;

    not g1 (a, z); // Invert select signal

    and g2 (b, x, a), // Output = x if z is 0
        g3 (c, y, z); // Output = y if z is 1

    or g4 (out, c, b); // Output = b OR c
endmodule

// 4-to-1 multiplexer.
module mux4x1 (w, x, y, z, ctrl, out);
    input w, x, y, z;
    input [1:0] ctrl; // Select signal
    output out;

    mux2x1 mux1 (w, x, ctrl[0], mux1out), // 2-to-1 mux 1
           mux2 (y, z, ctrl[0], mux2out), // 2-to-1 mux 2
           mux3 (mux1out, mux2out, ctrl[1], out); // 2-to-1 mux 3
endmodule

// 1-bit ALU.
module ALU1 (a, b, ainvert, binvert, op, less, carryin, carryout, result);
    input a, b, less, carryin, ainvert, binvert;
    input [1:0] op; // Operation select
    output carryout, result;
    wire nota, notb, c, d, e, f, sum;

    not na (nota, a), // Invert a
        nb (notb, b); // Invert b

    mux2x1 muxa (a, nota, ainvert, c), // Select a or ~a
           muxb (b, notb, binvert, d); // Select b or ~b

    and ag1 (e, c, d); // AND operation
    or og1 (f, c, d); // OR operation

    full_adder fa (c, d, carryin, carryout, sum); // Full adder for addition

    mux4x1 muxop (e, f, sum, less, op, result); // Select ALU output based on op
endmodule

// 1-bit ALU for the most significant bit (MSB).
module ALUmsb (a, b, ainvert, binvert, op, less, carryin, carryout, result, set);
    input a, b, less, carryin, ainvert, binvert;
    input [1:0] op;
    output carryout, result, set;
    wire nota, notb, c, d, f, g;

    not na (nota, a),
        nb (notb, b);

    mux2x1 muxa (a, nota, ainvert, c),
           muxb (b, notb, binvert, d);

    and ag2 (f, c, d);
    or og2 (g, c, d);

    full_adder fa (c, d, carryin, carryout, set);

    mux4x1 muxop (f, g, set, less, op, result);
endmodule

// 16-bit ALU.
module alu (op, a, b, ALUout, zero);
    input [3:0] op;
    input [15:0] a, b;
    output [15:0] ALUout;
    // zero and overflow
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
         alu10 (a[10], b[10], op[3], op[2], op[1:0], 1'b0, c10, c11, ALUout[10]),
         alu11 (a[11], b[11], op[3], op[2], op[1:0], 1'b0, c11, c12, ALUout[11]),
         alu12 (a[12], b[12], op[3], op[2], op[1:0], 1'b0, c12, c13, ALUout[12]),
         alu13 (a[13], b[13], op[3], op[2], op[1:0], 1'b0, c13, c14, ALUout[13]),
         alu14 (a[14], b[14], op[3], op[2], op[1:0], 1'b0,c14,c15,ALUout[14]); 
    
    ALUmsb alu15 (a[15],b[15],op[3],op[2],op[1:0],1'b0,c14, c15,ALUout[15],set); 
    
    nor nor1(zero, ALUout[0],ALUout[1],ALUout[2],ALUout[3]); 
endmodule 

module MainControl (Op, Control); 
  input [3:0] Op; //change this from 6 to 4 bits
  output reg [6:0] Control; //change this from 8 to 11 bits
// RegDst,ALUSrc,MemtoReg,RegWrite,MemWrite,Beq,Bne,ALUCtl //changed branch to beq and bne, and ALUOp to AluCtl
  always @(Op) case (Op)
    4'b0000: Control <= 11'b10010_0_0_0010; // ADD
    4'b0001: Control <= 11'b10010_0_0_0110; // SUB
    4'b0010: Control <= 11'b10010_0_0_0000; // AND
    4'b0011: Control <= 11'b10010_0_0_0001; // OR
    4'b0100: Control <= 11'b10010_0_0_1100; // NOR
    4'b0101: Control <= 11'b10010_0_0_1101; // NAND
    4'b0110: Control <= 11'b10010_0_0_0111; // SLT
    4'b0111: Control <= 11'b01010_0_0_0010; // ADDI
  endcase
endmodule

// Selects between two 2-bit inputs (I0 and I1) based on control signal Sel. 
module doublemux2x1 (I0,I1,Sel,Out); 
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
module sexdecuplexmux2x1 (I0,I1,Sel,Out); 
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


/* the zero control bit decides whether beq or bne is selected
if zero -> beq
if !zero -> bne
beq is branch is inputs are equal, bne branches if not equal
if branch occurs, program counter will increment to the target address
if no branch, PCplus4 */

module branchmux(Bne,Beq,Zero,Target,PCplus4,NextPC);
    input Beq,Bne,Zero;
    input [15:0] Target,PCplus4;
    output [15:0] NextPC;
    wire Out;
    
    mux2x1 branch(Bne,Beq,Zero,Out);
    sexdecuplexmux2x1 nextpc(PCplus4,Target,Out,NextPC);
endmodule

module CPU (clock, PC, IFID_IR, IDEX_IR, WD);
  
  initial begin
    // Program with nop's - no hazards
    IMemory[0]  = 16'b0111_00_01_00001111;  // addi $t1, $0,  15   ($t1=15)
    IMemory[1]  = 16'b0111_00_10_00000111;  // addi $t2, $0,  7    ($t2= 7)
    IMemory[2]  = 16'b0000000000000000;  // nop
    IMemory[3]  = 16'b0010_01_10_11_000000;  // and  $t3, $t1, $t2  ($t3= 7)
    IMemory[4]  = 16'b0000000000000000;  // nop
    IMemory[5]  = 16'b0001_01_11_10_000000;  // sub  $t2, $t1, $t3  ($t2= 8)
    IMemory[6]  = 16'b0000000000000000;  // nop
    IMemory[7]  = 16'b0011_10_11_10_000000;  // or   $t2, $t2, $t3  ($t2=15)
    IMemory[8]  = 16'b0000000000000000;  // nop
    IMemory[9]  = 16'b0000_10_11_11_000000;  // add  $t3, $t2, $t3  ($t3=22)
    IMemory[10] = 16'b0000000000000000;  // nop
    IMemory[11] = 16'b0100_10_11_01_000000;  // nor  $t1, $t2, $t3  ($t1=-32)
    IMemory[12] = 16'b0110_11_10_01_000000;  // slt  $t1, $t3, $t2  ($t1= 0)
    IMemory[13] = 16'b0110_10_11_01_000000;  // slt  $t1, $t2, $t3  ($t1= 1)
  end
  /*
  initial begin 
    //Program without nop's - wrong results due to data hazards
     IMemory[0] = 16'b0111_00_01_00001111;  // addi $t1, $0,  15   ($t1=15)
     IMemory[1] = 16'b0111_00_10_00000111;  // addi $t2, $0,  7    ($t2= 7)
     IMemory[2] = 16'b0010_01_10_11_000000;  // and  $t3, $t1, $t2  ($t3= 7)
     IMemory[3] = 16'b0001_01_11_10_000000;  // sub  $t2, $t1, $t3  ($t2= 8)
     IMemory[4] = 16'b0011_10_11_10_000000;  // or   $t2, $t2, $t3  ($t2=15)
     IMemory[5] = 16'b0000_10_11_11_000000;  // add  $t3, $t2, $t3  ($t3=22)
     IMemory[6] = 16'b0100_10_11_01_000000;  // nor  $t1, $t2, $t3  ($t1=-32)
     IMemory[7] = 16'b0110_11_10_01_000000;  // slt  $t1, $t3, $t2  ($t1= 0)
     IMemory[8] = 16'b0110_10_11_01_000000;  // slt  $t1, $t2, $t3  ($t1= 1)
  end
  */

  input clock;
  output [15:0] PC, IFID_IR, IDEX_IR, WD;

  // === IF STAGE ===
  wire [15:0] NextPC;
  reg[15:0] PC, IMemory[0:1023];
  // --------------------------------
  reg[15:0] IFID_IR;
  // --------------------------------
  alu fetch (4'b0010, PC, 16'b10, NextPC, Unused);


  // === ID STAGE ===
  wire [6:0] Control;
  wire [15:0] RD1, RD2, SignExtend, WD;
  wire [15:0] FWD_RD1, FWD_RD2; // Outputs of the forwarding muxes
  reg [15:0] IDEX_IR; // For monitoring the pipeline
  reg IDEX_RegWrite, IDEX_ALUSrc, IDEX_RegDst;
  reg [3:0] IDEX_ALUOp;
  reg [15:0] IDEX_RD1, IDEX_RD2, IDEX_SignExt;
  reg [1:0]  IDEX_rt, IDEX_rd;
  wire [1:0] WR;

  reg_file rf (IFID_IR[11:10], IFID_IR[9:8], WR, WD, IDEX_RegWrite, RD1, RD2, clock);
  MainControl MainCtr (IFID_IR[15:12], Control); 
  assign SignExtend = {{8{IFID_IR[7]}},IFID_IR[7:0]}; // sign extension

  // === EXE STAGE ===
  wire [15:0] B, ALUOut;
  wire [3:0] ALUctl;
  alu ex (IDEX_ALUOp, IDEX_RD1, B, ALUOut, Zero);
  sexdecuplexmux2x1 ALUCtrl (IDEX_RD2, IDEX_SignExt, IDEX_ALUSrc, B);
  doublemux2x1 wrmux (IDEX_rd, IDEX_rt, IDEX_RegDst, WR);
  assign WD = ALUOut;

  // Forwarding multiplexers
  sexdecuplexmux2x1 fwd1 (RD1 ,ALUOut, IDEX_RegWrite && WR==IFID_IR[11:10], FWD_RD1),
                    fwd2 (RD2, ALUOut, IDEX_RegWrite && WR==IFID_IR[9:8], FWD_RD2);

  initial begin
    PC = 0;
    IFID_IR = 0; // clear pipeline register to avoid forwarding from empty pipeline
    IDEX_RegWrite = 0; 
  end

  // Running the pipeline
  always @(negedge clock) begin

    // Stage 1 - IF
    PC <= NextPC;
    IFID_IR <= IMemory[PC>>1];

    // Stage 2 - ID
    IDEX_IR <= IFID_IR; // For monitoring the pipeline
    // {RegDst,ALUSrc,MemtoReg,RegWrite,MemWrite,Beq,Bne,ALUctl}); 
    {IDEX_RegDst, IDEX_ALUSrc, IDEX_RegWrite, IDEX_ALUOp} <= Control;

    //  No Forwarding
    IDEX_RD1 <= RD1; 
    IDEX_RD2 <= RD2;

    //  Forwarding
    //  IDEX_RD1 <= FWD_RD1; 
    //  IDEX_RD2 <= FWD_RD2;

    IDEX_SignExt <= SignExtend;
    IDEX_rt <= IFID_IR[9:8];
    IDEX_rd <= IFID_IR[7:6];

    // Stage 3 - EX
    // No transfers needed here - on negedge WD is written into register WR
  end
endmodule

// Test module
module test ();
  reg clock;
  wire signed [15:0] PC,IFID_IR,IDEX_IR,WD;
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