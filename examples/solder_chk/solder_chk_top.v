`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module solder_chk_top (
    input wire clk_i,

    input wire EF_01,
    input wire EF_02,
    input wire EF_03,
    input wire EF_04,

    output wire EF_01,
    output wire EF_02,
    output wire EF_03,
    output wire EF_04
);

  localparam NUM_PINS = 4;

  wire [NUM_PINS-1:0] test_pins;
  wire [NUM_PINS-1:0] result_pins;
  wire error;

  assign result_pins = {EF_04_i, EF_03_i, EF_02_i, EF_01_i};
  assign {EF_04_o, EF_03_o, EF_02_o, EF_01_o} = test_pins;

  io_walker #(
      .NUM_PINS(4)
  ) uut (
      .clk_i(clk),
      .test_pins(test_pins),
      .result_pins(result_pins),
      .error_o(error)
  );

endmodule
