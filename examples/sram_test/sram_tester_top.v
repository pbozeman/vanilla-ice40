// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module sram_tester_top #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    input  wire CLK,
    input  wire reset,
    output wire test_done,
    output wire LED1,
    output wire LED2,

    // sram pins
    output wire [ADDR_BITS-1:0] SRAM_ADDR_BUS,
    inout wire [DATA_BITS-1:0] SRAM_DATA_BUS,
    output wire we_n,
    output wire oe_n,
    output wire ce_n
);

  // Internal signals
  wire [ADDR_BITS-1:0] addr;
  wire [DATA_BITS-1:0] data_write;
  wire [DATA_BITS-1:0] data_read;
  wire read_only;
  wire test_pass;

  // Instantiate the sram_tester
  sram_tester #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) tester (
      .clk(CLK),
      .reset(reset),
      .test_done(test_done),
      .test_pass(test_pass),
      .read_only(read_only),
      .addr(addr),
      .data_write(data_write),
      .data_read(data_read),
      .addr_bus(SRAM_ADDR_BUS),
      .data_bus(SRAM_DATA_BUS),
      .we_n(we_n),
      .oe_n(oe_n),
      .ce_n(ce_n)
  );

  // LED1 blinks every addr reset (too fast to see, use a scope)
  assign LED1 = (addr == {ADDR_BITS{1'b0}});

  // LED2 is success
  assign LED2 = test_pass;

endmodule
