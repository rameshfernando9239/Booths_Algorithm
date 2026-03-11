`timescale 1ns / 1ps
// Top-level IEEE-754 Half-Precision MAC Unit
module MAC16_top #(
    //parameter PARM_RM             = 3,
    parameter PARM_XLEN           = 16
    // rounding modes
//    parameter PARM_RM_RNE         = 3'b000,
//    parameter PARM_RM_RTZ         = 3'b001,
//    parameter PARM_RM_RDN         = 3'b010,
//    parameter PARM_RM_RUP         = 3'b011,
//    parameter PARM_RM_RMM         = 3'b100
)(
//    input  wire [PARM_RM-1:0]      Rounding_mode_i,
    input  wire [PARM_XLEN-1:0]    A_i,
    input  wire [PARM_XLEN-1:0]    B_i,
    input  wire [PARM_XLEN-1:0]    C_i,
    // output wire [PARM_XLEN-1:0]    Result_o,
    // exception flags
    // output wire                    NV_o,
    // output wire                    OF_o,
    // output wire                    UF_o,
    // output wire                    NX_o
);

    // half-precision parameters
    parameter PARM_EXP            = 5;
    parameter PARM_MANT           = 10;
    parameter PARM_BIAS           = 15;
    parameter PARM_EXP_ONE        = {{PARM_EXP-1{1'b0}},1'b1};
    parameter PARM_LEADONE_WIDTH  = 6;  // ceil(log2(3*10+5))
    parameter PARM_MANT_NAN         = 10'b10_0000_0000;

    // -------------------------------------------------------------------------
    // extract fields
    // -------------------------------------------------------------------------
 
    wire A_Leadingbit = |A_i[PARM_XLEN-2:PARM_MANT];
    wire B_Leadingbit = |B_i[PARM_XLEN-2:PARM_MANT];
    wire C_Leadingbit = |C_i[PARM_XLEN-2:PARM_MANT];

    wire A_Inf, B_Inf, C_Inf;
    wire A_Zero, B_Zero, C_Zero;
    wire A_NaN, B_NaN, C_NaN;
    wire A_DeN, B_DeN, C_DeN;

    
    SpecialCaseDetector #(
        .PARM_EXP(PARM_EXP),
        .PARM_MANT(PARM_MANT)
        ) SpecialCaseDetector (
        .A_i(A_i),
        .B_i(B_i),
        .C_i(C_i),
        .A_Leadingbit_i(A_Leadingbit),
        .B_Leadingbit_i(B_Leadingbit),
        .C_Leadingbit_i(C_Leadingbit),        
        .A_Inf_o(A_Inf),
        .B_Inf_o(B_Inf),
        .C_Inf_o(C_Inf),
        .A_Zero_o(A_Zero),
        .B_Zero_o(B_Zero),
        .C_Zero_o(C_Zero),
        .A_NaN_o(A_NaN),
        .B_NaN_o(B_NaN),
        .C_NaN_o(C_NaN),
        .A_DeN_o(A_DeN),
        .B_DeN_o(B_DeN),
        .C_DeN_o(C_DeN)
    );
    wire A_sign = A_i[PARM_XLEN-1];
    wire B_sign = B_i[PARM_XLEN-1];
    wire C_sign = C_i[PARM_XLEN-1];

    // effective subtraction sign for add: A + B*C
    wire Sub_Sign = A_sign ^ B_sign ^ C_sign;
    //denormalized number has exponent 1 
    wire [PARM_EXP - 1: 0] A_exp = A_DeN ? PARM_EXP_ONE : A_i[PARM_XLEN - 2 : PARM_MANT];
    wire [PARM_EXP - 1: 0] B_exp = B_DeN ? PARM_EXP_ONE : B_i[PARM_XLEN - 2 : PARM_MANT];
    wire [PARM_EXP - 1: 0] C_exp = C_DeN ? PARM_EXP_ONE : C_i[PARM_XLEN - 2 : PARM_MANT];
    
    wire [PARM_MANT : 0] A_mant = {A_Leadingbit, A_i[PARM_MANT - 1 : 0]};
    wire [PARM_MANT : 0] B_mant = {B_Leadingbit, B_i[PARM_MANT - 1 : 0]};
    wire [PARM_MANT : 0] C_mant = {C_Leadingbit, C_i[PARM_MANT - 1 : 0]};
    // normalized mantissas with hidden bit
    // -------------------------------------------------------------------------
    // partial-product generation: B_mant * C_mant
    // -------------------------------------------------------------------------
    wire [2*PARM_MANT:0] pp00, pp01, pp02, pp03, pp04, pp05;
    //wire [2*PARM_MANT:0] pp06;
    R4BoothHalf #(
        .PARM_MANT(PARM_MANT)
        ) R4Booth (
        .MantA_i(B_mant),
        .MantB_i(C_mant),
        .pp_00_o(pp00), 
	    .pp_01_o(pp01), 
	    .pp_02_o(pp02),
        .pp_03_o(pp03), 
	    .pp_04_o(pp04), 
	    .pp_05_o(pp05)
        //.pp_06_o(pp06)
    );
    // -------------------------------------------------------------------------
    // Wallace tree reduction to two rows
    // -------------------------------------------------------------------------
    wire [2*PARM_MANT:0] Wallace_sum;
    wire [2*PARM_MANT:0] Wallace_carry;
    wire                   Wallace_suppression_sign_extension;
    WallaceTree #(
        .PARM_MANT(PARM_MANT)
        ) WallaceTree (
        .pp_00_i(pp00), 
	    .pp_01_i(pp01), 
	    .pp_02_i(pp02),
        .pp_03_i(pp03), 
	    .pp_04_i(pp04), 
	    .pp_05_i(pp05),
        .wallace_sum_o(Wallace_sum),
        .wallace_carry_o(Wallace_carry),
        .suppression_sign_extension_o(Wallace_suppression_sign_extension)
    );

endmodule