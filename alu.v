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

module multiplexer_4x1(X, Y, Z, W, S1, S2, out);
    input X, Y, Z, W;
    input S1, S2;
    output out;
    wire c1, c2;

    // 2x1 mux
    multiplexer_2x1 m1 (X, Y, S1, c1);
    multiplexer_2x1 m2 (Z, W, S1, c2);

    // combine the 2x1 muxes
    multiplexer_2x1 m3 (c1, c2, S2, out);
endmodule

module half_adder (A, B, S, C);
    input A, B;
    output S, C;
    
    xor g1 (S, A, B);
    and g2 (C, A, B);
endmodule

module full_adder (X, Y, Z, S, C);
    // X, Y, Carry in, Sum, Carry out
    input X, Y, Z;
    output S, C;
    wire S1, C1, C2; 
    
    half_adder HA1 (X, Y, S1, C1),
                HA2 (S1, Z, S, C2);
    or g1(C, C1, C2);
endmodule

module bit_alu_carry(A, B, L, CI, OP, R, CO);
    // A, B, Less, Carry in, Operation, Result, Carry out
    input A, B, L, CI;
    input [3:0] OP; 
    output R, CO;
    // not_a, a_mux_out, not_b, b_mux_out, a_b_and, a_b_or, a_b_add
    wire not_a, a_mux_out, not_b, b_mux_out, a_b_and, a_b_or, a_b_add;

    // A
    not (not_a, A);
    multiplexer_2x1 m1 (A, not_a, OP[3], a_mux_out);

    // B
    not n1 (not_b, B);
    multiplexer_2x1 m2 (B, not_b, OP[2], b_mux_out);

    // Operations
    and a1 (a_b_and, a_mux_out, b_mux_out);
    or o1 (a_b_or, a_mux_out, b_mux_out);
    full_adder fa1 (a_mux_out, b_mux_out, CI, a_b_add, CO);

    // Multiplexer
    multiplexer_4x1 m3 (a_b_and, a_b_or, a_b_add, L, OP[0], OP[1], R);
endmodule

module bit_alu_set(A, B, L, CI, OP, R, S, O);
    // A, B, Less, Carry in, Operation, Result, Set, Overflow
    input A, B, L, CI;
    input [3:0] OP; 
    // result, set, overflow
    output R, S, O;
    // not_a, a_mux_out, not_b, b_mux_out, a_b_and, a_b_or, a_b_add, Carry Out, Overflow xor out
    wire not_a, a_mux_out, not_b, b_mux_out, a_b_and, a_b_or, a_b_add, CO, O1;

    // A
    not n1 (not_a, A);
    multiplexer_2x1 m1 (A, not_a, OP[3], a_mux_out);

    // B
    not n2 (not_b, B);
    multiplexer_2x1 m2 (B, not_b, OP[2], b_mux_out);

    // Operations
    and a1 (a_b_and, a_mux_out, b_mux_out);
    or o1 (a_b_or, a_mux_out, b_mux_out);
    full_adder fa1 (a_mux_out, b_mux_out, CI, a_b_add, CO);
    assign S = a_b_add;

    // Multiplexer
    multiplexer_4x1 m3 (a_b_and, a_b_or, a_b_add, L, OP[0], OP[1], R);

    // Overflow
    xor x1 (O1, CI, CO);
    and a3 (O, O1, OP[1]);
endmodule

module ALU(OP, A, B, R, Z, O);
    input [15:0] A, B;
    input [3:0] OP;
    // zero and overflow
    output Z, O;
    // result
    output [15:0] R;
    // carry out and set
    wire CO0, CO1, CO2, CO3, CO4, CO5, CO6, CO7, CO8, CO9, CO10, CO11, CO12, CO13, CO14, CO15, S;

    // Bit 0
    bit_alu_carry ba0 (A[0], B[0], S, OP[2], OP, R[0], CO0);
    // Bit 1
    bit_alu_carry ba1 (A[1], B[1], 1'b0, CO0, OP, R[1], CO1);
    // Bit 2
    bit_alu_carry ba2 (A[2], B[2], 1'b0, CO1, OP, R[2], CO2);
    // Bit 3
    bit_alu_carry ba3 (A[3], B[3], 1'b0, CO2, OP, R[3], CO3);
    // Bit 4
    bit_alu_carry ba4 (A[4], B[4], 1'b0, CO3, OP, R[4], CO4);
    // Bit 5
    bit_alu_carry ba5 (A[5], B[5], 1'b0, CO4, OP, R[5], CO5);
    // Bit 6
    bit_alu_carry ba6 (A[6], B[6], 1'b0, CO5, OP, R[6], CO6);
    // Bit 7
    bit_alu_carry ba7 (A[7], B[7], 1'b0, CO6, OP, R[7], CO7);
    // Bit 8
    bit_alu_carry ba8 (A[8], B[8], 1'b0, CO7, OP, R[8], CO8);
    // Bit 9
    bit_alu_carry ba9 (A[9], B[9], 1'b0, CO8, OP, R[9], CO9);
    // Bit 10
    bit_alu_carry ba10 (A[10], B[10], 1'b0, CO9, OP, R[10], CO10);
    // Bit 11
    bit_alu_carry ba11 (A[11], B[11], 1'b0, CO10, OP, R[11], CO11);
    // Bit 12
    bit_alu_carry ba12 (A[12], B[12], 1'b0, CO11, OP, R[12], CO12);
    // Bit 13
    bit_alu_carry ba13 (A[13], B[13], 1'b0, CO12, OP, R[13], CO13);
    // Bit 14
    bit_alu_carry ba14 (A[14], B[14], 1'b0, CO13, OP, R[14], CO14);
    
    // Bit 15
    bit_alu_set ba15 (A[15], B[15], 1'b0, CO14, OP, R[15], S, O);

    // Zero
    nor o1 (Z, R[0], R[1], R[2], R[3], R[4], R[5], R[6], R[7], R[8], R[9], R[10], R[11], R[12], R[13], R[14], R[15]);
endmodule


module testALU;
  reg signed [15:0] a;
  reg signed [15:0] b;
  reg [3:0] op;
  wire signed [15:0] result;
  wire zero,overflow;
  ALU alu (op,a,b,result,zero,overflow);
  initial
    begin
     $display("op   a        b        result   zero overflow");
     $monitor ("%b %b(%d) %b(%d) %b(%d) %b    %b",op,a,a,b,b,result,result,zero,overflow);
	       op = 4'b0000; a = 16'b0000000000001100; b = 16'b0000000000011000;  // AND
    end
endmodule
/*
        #1 op = 4'b0001; a = 4'b0101; b = 4'b0010;  // OR
        #1 op = 4'b0010; a = 4'b0101; b = 4'b0001;  // ADD
	    #1 op = 4'b0010; a = 4'b0111; b = 4'b0001;  // ADD overflow (8+1=-8)
	    #1 op = 4'b0110; a = 4'b0101; b = 4'b0001;  // SUB
	    #1 op = 4'b0110; a = 4'b1111; b = 4'b0001;  // SUB
	    #1 op = 4'b0110; a = 4'b1111; b = 4'b1000;  // SUB no overflow (-1-(-8)=7)
	    #1 op = 4'b0110; a = 4'b1110; b = 4'b0111;  // SUB overflow (-2-7=7)
	    #1 op = 4'b0111; a = 4'b0101; b = 4'b0001;  // SLT
	    #1 op = 4'b0111; a = 4'b0001; b = 4'b0011;  // SLT
	    #1 op = 4'b0111; a = 4'b1101; b = 4'b0110;  // SLT overflow (-3-6=7 => SLT=0)
        #1 op = 4'b1100; a = 4'b0101; b = 4'b0001;  // NOR
        #1 op = 4'b1101; a = 4'b0101; b = 4'b0001;  // NAND
*/