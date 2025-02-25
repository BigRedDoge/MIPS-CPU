// 2x1 1 bit multiplexer
module multiplexer_2x1 (X, Y, Z, out);
    // Input X and Y, Select Z, Output out
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

// 4x1 1 bit multiplexer
module multiplexer_4x1(X, Y, Z, W, S1, S2, out);
    // Input X, Y, Z, W, Select S1, S2, Output out
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

// Half adder
module half_adder (A, B, S, C);
    // Input A, B, Sum, Carry
    input A, B;
    output S, C;
    
    xor g1 (S, A, B);
    and g2 (C, A, B);
endmodule

// Full adder
module full_adder (X, Y, Z, S, C);
    // X, Y, Carry in, Sum, Carry out
    input X, Y, Z;
    output S, C;
    wire S1, C1, C2; 
    
    half_adder HA1 (X, Y, S1, C1),
                HA2 (S1, Z, S, C2);
    or g1(C, C1, C2);
endmodule