`ifndef VGA_TEST_01_V
`define VGA_TEST_01_V

`include "directives.v"

`include "vga_mode.v"

module vga_test_01 (
    input       [COLUMN_BITS-1:0] column,
    input       [   ROW_BITS-1:0] row,
    output wire [            3:0] green,
    output wire [            3:0] red,
    output wire [            3:0] blue
);
  localparam COLUMN_BITS = $clog2(`VGA_MODE_H_WHOLE_LINE);
  localparam ROW_BITS = $clog2(`VGA_MODE_V_WHOLE_FRAME);

  localparam THIRD_SCREEN = `VGA_MODE_H_VISIBLE / 3;
  localparam RED_END = THIRD_SCREEN;
  localparam GRN_START = RED_END;
  localparam GRN_END = THIRD_SCREEN * 2;
  localparam BLU_START = GRN_END;
  localparam BLU_END = `VGA_MODE_H_VISIBLE;

  assign
      red = (row < `VGA_MODE_V_VISIBLE && column < RED_END) ? 4'b1111 : 4'b0000;
  assign green = (row < `VGA_MODE_V_VISIBLE && column >= GRN_START &&
                  column < GRN_END) ? 4'b1111 : 4'b0000;
  assign blue = (row < `VGA_MODE_V_VISIBLE && column >= BLU_START &&
                 column < BLU_END) ? 4'b1111 : 4'b0000;

endmodule

`endif
