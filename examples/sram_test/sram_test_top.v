// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module sram_test_top (
    input  wire CLK,
    output wire LED1,
    output wire LED2
);

  assign LED1 = 1'bZ;
  assign LED2 = 1'bZ;

endmodule
