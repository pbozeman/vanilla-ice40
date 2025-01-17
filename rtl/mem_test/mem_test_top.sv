`include "directives.sv"

`include "initial_reset.sv"
`include "mem_test.sv"

module mem_test_top #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // board signals
    input  logic CLK,
    output logic LED1,
    output logic LED2,

    // Buses
    output logic [ADDR_BITS-1:0] R_SRAM_ADDR_BUS,
    inout  wire  [DATA_BITS-1:0] R_SRAM_DATA_BUS,

    // Control signals
    output logic R_SRAM_CS_N,
    output logic R_SRAM_OE_N,
    output logic R_SRAM_WE_N,

    output logic [7:0] R_E,
    output logic [7:0] R_F
);
  logic reset;
  logic test_done;
  logic test_pass;

  initial_reset u_initial_reset (
      .clk  (CLK),
      .reset(reset)
  );

  mem_test #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) tester (
      .clk  (CLK),
      .reset(reset),

      .test_done(test_done),
      .test_pass(test_pass),

      .debug0(R_E),
      .debug1(R_F),

      .sram_io_addr(R_SRAM_ADDR_BUS),
      .sram_io_data(R_SRAM_DATA_BUS),
      .sram_io_ce_n(R_SRAM_CS_N),
      .sram_io_we_n(R_SRAM_WE_N),
      .sram_io_oe_n(R_SRAM_OE_N)
  );

  assign LED1 = test_done;
  assign LED2 = !test_pass;

endmodule
