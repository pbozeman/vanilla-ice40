`include "directives.v"

`include "vga_pll.v"
`include "vga_sync.v"
`include "vga_test_01.v"

`define VGA_RED_0 R_E_01
`define VGA_RED_1 R_E_02
`define VGA_RED_2 R_E_03
`define VGA_RED_3 R_E_04

`define VGA_BLUE_0 R_E_05
`define VGA_BLUE_1 R_E_06
`define VGA_BLUE_2 R_E_07
`define VGA_BLUE_3 R_E_08

`define VGA_GREEN_0 R_F_01
`define VGA_GREEN_1 R_F_02
`define VGA_GREEN_2 R_F_03
`define VGA_GREEN_3 R_F_04

`define VGA_HSYNC R_F_05
`define VGA_VSYNC R_F_06

module vga_top (
    input  wire CLK,
    output wire LED1,
    output wire LED2,
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
  localparam COLUMN_BITS = $clog2(`VGA_MODE_H_WHOLE_LINE);
  localparam ROW_BITS = $clog2(`VGA_MODE_V_WHOLE_FRAME);

  wire reset = 0;
  wire visible;

  wire [COLUMN_BITS-1:0] column;
  wire [ROW_BITS-1:0] row;

  wire [3:0] red;
  wire [3:0] green;
  wire [3:0] blue;

  wire vga_clk;
  wire enable = 1'b1;

  vga_pll vga_pll_inst (
      .clk_i(CLK),
      .clk_o(vga_clk)
  );

  vga_sync vga_inst (
      .clk(vga_clk),
      .reset(reset),
      .enable(enable),
      .visible(visible),
      .hsync(`VGA_HSYNC),
      .vsync(`VGA_VSYNC),
      .column(column),
      .row(row)
  );

  vga_test_01 vga_pattern (
      .column(column),
      .row(row),
      .red(red),
      .green(green),
      .blue(blue)
  );

  assign LED1 = 1'bZ;
  assign LED2 = 1'bZ;

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
