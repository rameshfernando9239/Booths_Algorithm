`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  WallaceTree for IEEE-754 Half-Precision (binary16)
//   - PARM_MANT = 10 → mantissa bits (excl. hidden “1”)
//   - 6 Radix-4 Booth partial products + 1 sign‐extension word → 7 inputs
//   - Generic CSA tree in three levels
//////////////////////////////////////////////////////////////////////////////////

module WallaceTree #(
  parameter PARM_MANT = 10
)(
  // 7 partial products: pp0..pp5 are the Booth PPs, pp6 is the sign‐extension
  input [2*PARM_MANT:0] pp_00_i,  // width=2*(10)+2+1=23
  input [2*PARM_MANT:0] pp_01_i,
  input [2*PARM_MANT:0] pp_02_i,
  input [2*PARM_MANT:0] pp_03_i,
  input [2*PARM_MANT:0] pp_04_i,
  input [2*PARM_MANT:0] pp_05_i,
  //input [2*PARM_MANT+2 : 0] pp_06_i,  // sign‐extend is one bit narrower
  // Final 2-row result
  output [2*PARM_MANT:0] wallace_sum_o,
  output [2*PARM_MANT:0] wallace_carry_o,
  output                 suppression_sign_extension_o
);

  //--------------------------------------------------------------------------- 
  // 1) First CSA layer: group 3 PPs at a time into sum/carry
  //--------------------------------------------------------------------------- 
  wire [2*PARM_MANT:0] csa_sum  [1:0];
  wire [2*PARM_MANT:0] csa_carry[1:0];
  wire [2*PARM_MANT:0] csa_shcy [1:0];

  // PP0,PP1,PP2 → CSA0
  Compressor32 #(2*PARM_MANT+1) LV1_0 (
    .A_i(pp_00_i), 
    .B_i(pp_01_i), 
    .C_i(pp_02_i),
    .Sum_o(csa_sum[0]), 
    .Carry_o(csa_carry[0])
  );

  // PP3,PP4,PP5 → CSA1
  Compressor32 #(2*PARM_MANT+1) LV1_1 (
    .A_i(pp_03_i), 
    .B_i(pp_04_i), 
    .C_i(pp_05_i),
    .Sum_o(csa_sum[1]), 
    .Carry_o(csa_carry[1])
  );


  // shift carries left by one for next level
  genvar i;
  generate
    for (i = 0; i < 2; i = i + 1) begin
      assign csa_shcy[i] = csa_carry[i] << 1;
    end
  endgenerate


  //--------------------------------------------------------------------------- 
  // 2) Second CSA layer: collapse CSA0 & CSA1 into one
  //--------------------------------------------------------------------------- 

  // sum0, carry0<<1, sum1, carry1<<1 → mid
  Compressor42 #(2*PARM_MANT+1) LV2 (
    .A_i(csa_sum[0]),
    .B_i(csa_shcy[0]),
    .C_i(csa_sum[1]),
    .D_i(csa_shcy[1]),
    .Sum_o(wallace_sum_o),
    .Carry_o(wallace_carry_o),
    .hidden_carry_msb(suppression_sign_extension_o)
  );

endmodule

