`timescale 1ns/1ps
module R4BoothHalf #(
    // number of fraction bits in IEEE?754 binary16
    parameter PARM_MANT = 10  // hidden_bit + fraction = 1 + 10 = 11 bits
)(
    input  wire [PARM_MANT:0]       MantA_i,   // {hidden, fraction}
    input  wire [PARM_MANT:0]       MantB_i,

    // partial products pp_00_o through pp_06_o
    output [2*PARM_MANT:0] pp_00_o,
    output [2*PARM_MANT:0] pp_01_o,
    output [2*PARM_MANT:0] pp_02_o,
    output [2*PARM_MANT:0] pp_03_o,
    output [2*PARM_MANT:0] pp_04_o,
    output [2*PARM_MANT:0] pp_05_o
	//output [2*PARM_MANT+2:0] pp_06_o
);

  // number of Booth windows: ceil((PARM_MANT+1 + 1 + 1)/2) = (PARM_MANT + 4)/2
  parameter PP = (PARM_MANT+1+1) / 2; // 6 in the case of Half precision

  // pad B with one MSB zeros and one LSB zero (for b[-1])
  wire [PARM_MANT+2:0] Bpad = { 1'b0, MantB_i, 1'b0 }; //13 bits

  // Booth control signals
  wire [PP-1:0] oneX, twoX, signB;
  genvar k;
  generate
    for (k = 0; k < PP; k = k + 1) begin : GEN_CTRL
      // ?1?A when b1^b0 == 1
      assign oneX[k] = Bpad[k*2] ^ Bpad[k*2+1];
      // ?2?A for patterns 100 or 011
      assign twoX[k] = ((~Bpad[k*2]) & (~Bpad[k*2 + 1]) & (Bpad[k*2 + 2])) || ((Bpad[k*2]) & (Bpad[k*2+1]) & (~Bpad[k*2+2]));
      // sign = top bit of the window
      assign signB[k] = Bpad[k*2 + 2];
    end
  endgenerate

  // generate raw unsigned partial products (width = PARM_MANT+2)
  reg [PARM_MANT+1:0] booth_PP_tmp [PP-1:0]; //12-bits
  wire [PARM_MANT+1:0] booth_PP [PP-1:0]; //12-bits

  integer idx;
  always @(*) begin
    for (idx = 0; idx < PP; idx = idx + 1) begin
	if (oneX[idx]) booth_PP_tmp[idx] = MantA_i;
	else if (twoX[idx]) booth_PP_tmp[idx] = MantA_i << 1;
	else booth_PP_tmp[idx] = 0;
    end
  end

  generate
	genvar j;
	for (j=0; j<PP; j=j+1) begin
		assign booth_PP[j] = signB[j] ? ~booth_PP_tmp[j] : booth_PP_tmp[j];
	end
  endgenerate

  //assign pp_00_o = {10'd0, ~signB[0], {}};
assign pp_00_o = {
    6'd0,                     // 24 − (1+2+W) = 10 leading zeros
    ~signB[0],               // bias invert
    {2{signB[0]}},           // bias sign-fill
    booth_PP[0]                // raw 11-bit partial product
};

// pp_01_o: window 1 gets a single “1” in the prefix (the top of its triangle),
// plus an LSB-zero and carry-in = signB[0]
assign pp_01_o = {
    6'd1,                     // prefix=10 bits with a single LSB=1
    ~signB[1],               // invert sign if negative
    booth_PP[1],               // 11-bit PP
    1'b0,                      // fixed LSB zero
    signB[0]                 // carry-in from window 0
};

// pp_02_o: shift by 2 bits, so we add 2 trailing zeros
assign pp_02_o = {
    4'd1,                     // 24−(1+W+1+1+2)=8-bit prefix with 1 in LSB
    ~signB[2],
    booth_PP[2],
    1'b0,
    signB[1],
    2'd0                       // 2 trailing zeros
};

// pp_03_o
assign pp_03_o = {
    2'd1,                     // 24−(1+W+1+1+4)=6
    ~signB[3],
    booth_PP[3],
    1'b0,
    signB[2],
    4'd0
};

// pp_04_o
assign pp_04_o = {                     // 24−(1+W+1+1+6)=4
    ~signB[4],
    booth_PP[4],
    1'b0,
    signB[3],
    6'd0
};

// pp_06_o: the last window; no prefix bits remain
assign pp_05_o = {              // invert sign
    booth_PP[5][PARM_MANT:0],               // 11-bit PP
    1'b0,                      // LSB zero
    signB[4],                // carry-in
    8'd0                      // 10 trailing zeros (2*6)
};

endmodule


