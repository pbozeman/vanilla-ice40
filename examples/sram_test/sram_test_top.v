// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module sram_test_top (
    input  wire clk_i,
    output wire led1_o,
    output wire led2_o
);

  assign led1_o = 1'bZ;
  assign led2_o = 1'bZ;

endmodule
