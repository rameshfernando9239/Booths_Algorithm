`timescale 1ns/1ps
module tb_MAC16_top;
  // half-precision parameters
  localparam EXP_W   = 5;
  localparam MANT_W  = 10;
  localparam XLEN    = 1 + EXP_W + MANT_W;
  localparam BIAS    = (1<<(EXP_W-1)) - 1; // 15

  // rounding modes
  reg [2:0] rm;
  localparam RNE = 3'b000, RTZ = 3'b001, RDN = 3'b010, RUP = 3'b011, RMM = 3'b100;

  // inputs & outputs
  reg  [XLEN-1:0] A, B, C;
  wire [XLEN-1:0] Y;
  wire [2*MANT_W+2:0] wallace_sum;
  wire [2*MANT_W+2:0] wallace_carry;
  wire                suppression_sign_extension;
//   wire                NV, OF, UF, NX;

  // instantiate DUT
  MAC16_top #(
    .PARM_XLEN(16)
    // .PARM_RM_RNE(RNE), 
	//   .PARM_RM_RTZ(RTZ),
    // .PARM_RM_RDN(RDN), 
	//   .PARM_RM_RUP(RUP),
    // .PARM_RM_RMM(RMM)
  ) dut (
    // .Rounding_mode_i(rm),
    .A_i(A), 
	.B_i(B), 
	.C_i(C),
	.wall_sum(wallace_sum),
	.wall_carry(wallace_carry),
	.wall_sext(suppression_sign_extension)
    	// .Result_o(Y),
    	// .NV_o(NV), 
	// .OF_o(OF), 
	// .UF_o(UF), 
	// .NX_o(NX)
  );

  // helper to print a test vector (hex values only)
  task automatic do_test(
    	input [XLEN-1:0] a0, 
    	input [XLEN-1:0] b0, 
		input [XLEN-1:0] c0,
		input [XLEN-1:0] expectValue, 
		input [2:0] mode, 
		input name
  ); begin
  
	//string name="";
    A = a0; B = b0; C = c0; rm = mode;
    #1;
    // $display("A=%h | B=%h | C=%h |", A, B, C);
    $display("%s | rm=%b | A=%h | B=%h | C=%h | Y=%h | expc=%h | NV=%b OF=%b UF=%b NX=%b",
     name, rm, A, B, C, Y, expectValue, NV, OF, UF, NX
    );
    if (Y !== expectValue) $error("    ? Expected %h", expectValue);
    else             $display("    ?");
    // $display("");
  end 
 endtask


 task automatic wallace_test(
    input [XLEN-1:0] a0,
    input [XLEN-1:0] b0,
    input [2*MANT_W+2:0] wallace_sum;
    input [2*MANT_W+2:0] wallace_carry;
    input                suppression_sign_extension;
 ); begin

    A = a0; B = b0; Wallace_sum=wallace_sum; Wallace_carry=wallace_carry; Suppression_sign_extension=suppression_sign_extension
    #1;
    // $display("A=%h | B=%h | C=%h |", A, B, C);
    $display("A=%h | B=%h | Wallace Sum=%h | Wallace Carry=%h | Sign Extension=%h ",
     A, B, Wallace_sum, Wallace_carry, Suppression_sign_extension
    );
    // if (Y !== expectValue) $error("    ? Expected %h", expectValue);
    // else             $display("    ?");

 end

 endtask

  initial begin
    $display("\n=== Half Precision MAC16_top HEX Only Testbench ===\n");

    // 1) 1.0 + (2.0 * 3.0) = 7.0
    // do_test(16'h3C00, 16'h4000, 16'h4200, 16'h4700, RNE, "1 + (2?3)");
    // 1.0 + (1.085*1.582)
    wallace_test(16'h3C00, 16'h3C57, 16'h3E53);

    // 2) -1.5 + (0.5 * -4.0) = -3.5
    // do_test(16'hBE00, 16'h3800, 16'hC400, 16'hC300, RNE, "-1.5+(0.5?-4)");

    // 3) Inf + (1 * 2) = Inf
    // do_test(16'h7C00, 16'h3C00, 16'h4000, 16'h7C00, RNE, "Inf + (1?2)");

    // 4) NaN propagation
    // do_test(16'h7E00, 16'h3C00, 16'h4000, 16'h7E00, RNE, "NaN + (1?2)");

    // 5) Underflow example: 2^-14 + (2^-14 ? 1) -> 2^-13 = 0x0500
    // do_test(16'h0400, 16'h0400, 16'h3C00, 16'h0500, RNE, "2^-14+(2^-14?1)");

    // 6) Rounding modes on overflowing multiply: 0 + (max?max)
    //do_test(16'h0000, 16'h7BFF, 16'h7BFF, 16'h7BFF, RTZ, "Overflow RTZ");
    // do_test(16'h0000, 16'h7BFF, 16'h7BFF, 16'h7BFF, RNE, "Overflow RNE");
    // do_test(16'h0000, 16'h7BFF, 16'h7BFF, 16'h7BFF, RDN, "Overflow RDN");
    // do_test(16'h0000, 16'h7BFF, 16'h7BFF, 16'h7BFF, RUP, "Overflow RUP");
    // do_test(16'h0000, 16'h7BFF, 16'h7BFF, 16'h7BFF, RMM, "Overflow RMM");

    $display("=== Testbench Complete ===");
    $finish;
  end
endmodule



