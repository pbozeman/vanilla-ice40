`ifndef VGA_DEF_V
`define VGA_DEV_V

`include "directives.v"

// verilog_format: off
`ifdef VGA_MODE_1024_768_60
  // icepll -i 100 -o 65
  `define VGA_MODE_PLL_DIVR (4'd4)
  `define VGA_MODE_PLL_DIVF (7'd51)
  `define VGA_MODE_PLL_DIVQ (3'd4)
  `define VGA_MODE_PLL_FILTER_RANGE (3'd2)
`else
  // icepll -i 100 -o 25
  `define VGA_MODE_PLL_DIVR (4'd0)
  `define VGA_MODE_PLL_DIVF (7'd7)
  `define VGA_MODE_PLL_DIVQ (3'd5)
  `define VGA_MODE_PLL_FILTER_RANGE (3'd5)
`endif
// verilog_format: on

`endif
