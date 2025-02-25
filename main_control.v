/*
Main Control module
Only behavior model required
*/
module MainControl (Op,Control); 
  input [5:0] Op;
  output reg [4:0] Control;
// Control bits: RegDst,ALUSrc,RegWrite,ALUOp
  always @(Op) case (Op)
    6'b000000: Control <= 5'b10110; // Rtype
    6'b001000: Control <= 5'b01100; // ADDI
  endcase
endmodule