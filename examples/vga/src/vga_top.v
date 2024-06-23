// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

`define VGA_RED_0 EF_01
`define VGA_RED_1 EF_02
`define VGA_RED_2 EF_03
`define VGA_RED_3 EF_04

`define VGA_BLUE_0 EF_05
`define VGA_BLUE_1 EF_06
`define VGA_BLUE_2 EF_07
`define VGA_BLUE_3 EF_08

`define VGA_GREEN_0 GH_01
`define VGA_GREEN_1 GH_02
`define VGA_GREEN_2 GH_03
`define VGA_GREEN_3 GH_04

`define VGA_HSYNC GH_05
`define VGA_VSYNC GH_06

module vga_top (
    input  wire clk_i,
    output wire led1_o,
    output wire led2_o,
    output wire `VGA_RED_0,
    output wire `VGA_RED_1,
    output wire `VGA_RED_2,
    output wire `VGA_RED_3,
    output wire `VGA_BLUE_0,
    output wire `VGA_BLUE_1,
    output wire `VGA_BLUE_2,
    output wire `VGA_BLUE_3,
    output wire `VGA_GREEN_0,
    output wire `VGA_GREEN_1,
    output wire `VGA_GREEN_2,
    output wire `VGA_GREEN_3,
    output wire `VGA_HSYNC,
    output wire `VGA_VSYNC
);

  wire reset = 0;
  wire visible;

  wire [9:0] column;
  wire [9:0] row;

  wire [3:0] red;
  wire [3:0] green;
  wire [3:0] blue;

  wire vga_clk;

  pll_vga pll_vga_inst (
      .clk_i(clk_i),
      .clk_o(vga_clk)
  );

  vga vga_inst (
      .clk_i(vga_clk),
      .reset_i(reset),
      .visible_o(visible),
      .hsync_o(`VGA_HSYNC),
      .vsync_o(`VGA_VSYNC),
      .column_o(column),
      .row_o(row)
  );

  vga_test_01 vga_pattern (
      .column_i(column),
      .row_i(row),
      .red_o(red),
      .green_o(green),
      .blue_o(blue)
  );

  assign led1_o = 1'bZ;
  assign led2_o = 1'bZ;

  assign `VGA_RED_0 = red[0];
  assign `VGA_RED_1 = red[1];
  assign `VGA_RED_2 = red[2];
  assign `VGA_RED_3 = red[3];

  assign `VGA_GREEN_0 = green[0];
  assign `VGA_GREEN_1 = green[1];
  assign `VGA_GREEN_2 = green[2];
  assign `VGA_GREEN_3 = green[3];

  assign `VGA_BLUE_0 = blue[0];
  assign `VGA_BLUE_1 = blue[1];
  assign `VGA_BLUE_2 = blue[2];
  assign `VGA_BLUE_3 = blue[3];

  // hysnc and vsync are driven directly by vga_inst

endmodule
