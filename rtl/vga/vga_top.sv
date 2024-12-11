`include "directives.sv"

`include "vga_pll.sv"
`include "vga_sync.sv"
`include "vga_test_01.sv"

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
    input  logic CLK,
    output logic LED1,
    output logic LED2,
    output logic `VGA_RED_0,
    output logic `VGA_RED_1,
    output logic `VGA_RED_2,
    output logic `VGA_RED_3,
    output logic `VGA_BLUE_0,
    output logic `VGA_BLUE_1,
    output logic `VGA_BLUE_2,
    output logic `VGA_BLUE_3,
    output logic `VGA_GREEN_0,
    output logic `VGA_GREEN_1,
    output logic `VGA_GREEN_2,
    output logic `VGA_GREEN_3,
    output logic `VGA_HSYNC,
    output logic `VGA_VSYNC
);
  localparam H_VISIBLE     = `VGA_MODE_H_VISIBLE;
  localparam H_FRONT_PORCH = `VGA_MODE_H_FRONT_PORCH;
  localparam H_SYNC_PULSE  = `VGA_MODE_H_SYNC_PULSE;
  localparam H_BACK_PORCH  = `VGA_MODE_H_BACK_PORCH;
  localparam H_WHOLE_LINE  = `VGA_MODE_H_WHOLE_LINE;

  localparam V_VISIBLE     = `VGA_MODE_V_VISIBLE;
  localparam V_FRONT_PORCH = `VGA_MODE_V_FRONT_PORCH;
  localparam V_SYNC_PULSE  = `VGA_MODE_V_SYNC_PULSE;
  localparam V_BACK_PORCH  = `VGA_MODE_V_BACK_PORCH;
  localparam V_WHOLE_FRAME = `VGA_MODE_V_WHOLE_FRAME;

  localparam FB_X_BITS  = $clog2(H_WHOLE_LINE);
  localparam FB_Y_BITS  = $clog2(V_WHOLE_FRAME);

  logic reset = 0;

  // verilator lint_off UNUSEDSIGNAL
  logic visible;
  // verilator lint_on UNUSEDSIGNAL

  logic [FB_X_BITS-1:0] x;
  logic [FB_Y_BITS-1:0] y;

  logic [3:0] red;
  logic [3:0] green;
  logic [3:0] blue;

  logic vga_clk;
  logic inc = 1'b1;

  vga_pll vga_pll_inst (
      .clk_i(CLK),
      .clk_o(vga_clk)
  );

  vga_sync #(
      .H_VISIBLE    (H_VISIBLE),
      .H_FRONT_PORCH(H_FRONT_PORCH),
      .H_SYNC_PULSE (H_SYNC_PULSE),
      .H_BACK_PORCH (H_BACK_PORCH),
      .H_WHOLE_LINE (H_WHOLE_LINE),
      .V_VISIBLE    (V_VISIBLE),
      .V_FRONT_PORCH(V_FRONT_PORCH),
      .V_SYNC_PULSE (V_SYNC_PULSE),
      .V_BACK_PORCH (V_BACK_PORCH),
      .V_WHOLE_FRAME(V_WHOLE_FRAME)
  ) vga_inst (
      .clk(vga_clk),
      .reset(reset),
      .inc(inc),
      .visible(visible),
      .hsync(`VGA_HSYNC),
      .vsync(`VGA_VSYNC),
      .x(x),
      .y(y)
  );

  vga_test_01 #(
      .H_VISIBLE   (H_VISIBLE),
      .H_WHOLE_LINE(H_WHOLE_LINE),

      .V_VISIBLE    (V_VISIBLE),
      .V_WHOLE_FRAME(V_WHOLE_FRAME)
  ) vga_pattern (
      .x(x),
      .y(y),
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
