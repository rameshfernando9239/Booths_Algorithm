`timescale 1ns/1ps

module tb_R4BoothHalf;
  // Parameters
  parameter PARM_MANT = 10;

  // Inputs
  reg [PARM_MANT:0] MantA_i;
  reg [PARM_MANT:0] MantB_i;

  // Outputs
  wire [2*PARM_MANT:0] pp_00_o;
  wire [2*PARM_MANT:0] pp_01_o;
  wire [2*PARM_MANT:0] pp_02_o;
  wire [2*PARM_MANT:0] pp_03_o;
  wire [2*PARM_MANT:0] pp_04_o;
  wire [2*PARM_MANT:0] pp_05_o;

  // Instantiate the Unit Under Test (UUT)
  R4BoothHalf #(
    .PARM_MANT(PARM_MANT)
  ) uut (
    .MantA_i(MantA_i),
    .MantB_i(MantB_i),
    .pp_00_o(pp_00_o),
    .pp_01_o(pp_01_o),
    .pp_02_o(pp_02_o),
    .pp_03_o(pp_03_o),
    .pp_04_o(pp_04_o),
    .pp_05_o(pp_05_o)
  );

  integer i=0;

  initial begin
    // Dump waveforms
    //$dumpfile("tb_R4BoothHalf.vcd");
    //$dumpvars(0, tb_R4BoothHalf);

    // Test cases
    MantA_i = 0; MantB_i = 0;
    #10; $display("Zero x Zero => MantA=0x%h, MantB=0x%h, pp00=0x%h ... pp05=0x%h", MantA_i, MantB_i, pp_00_o, pp_05_o);

    MantA_i = {1'b0, {PARM_MANT{1'b1}}}; // max fraction only
    MantB_i = {1'b0, {PARM_MANT{1'b1}}};
    #10; $display("MaxFrac x MaxFrac => MantA=0x%h, MantB=0x%h, pp00=0x%h ... pp05=0x%h", MantA_i, MantB_i, pp_00_o, pp_05_o);

    MantA_i = 11'h3FF; // all ones
    MantB_i = 11'h001; // minimal
    #10; $display("AllOnes x Min => MantA=0x%h, MantB=0x%h, pp00=0x%h ... pp05=0x%h", MantA_i, MantB_i, pp_00_o, pp_05_o);
	
	MantA_i = 11'h400;
	MantB_i = 11'h600;
	#10;
     $display("Test: MantA=0x%h, MantB=0x%h, pp00=0x%h, pp01=0x%h, pp02=0x%h, pp03=0x%h, pp04=0x%h, pp05=0x%h", MantA_i, MantB_i, pp_00_o, pp_01_o, pp_02_o, pp_03_o, pp_04_o, pp_05_o);
    // Random tests
	
	MantA_i = 11'b10001010111;
    MantB_i = 11'h653;
	#10;
     $display("Test: MantA=0x%h, MantB=0x%h, pp00=0x%h, pp01=0x%h, pp02=0x%h, pp03=0x%h, pp04=0x%h, pp05=0x%h", MantA_i, MantB_i, pp_00_o, pp_01_o, pp_02_o, pp_03_o, pp_04_o, pp_05_o);
    // Random tests
    for (i = 0; i < 10; i = i + 1) begin
      MantA_i = $random;
      MantB_i = $random;
      #10;
      $display("Test%d: MantA=0x%h, MantB=0x%h, pp00=0x%h, pp01=0x%h, pp02=0x%h, pp03=0x%h, pp04=0x%h, pp05=0x%h", 
                i, MantA_i, MantB_i, pp_00_o, pp_01_o, pp_02_o, pp_03_o, pp_04_o, pp_05_o);
    end

    $finish;
  end

endmodule