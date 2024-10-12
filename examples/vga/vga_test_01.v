`ifndef VGA_TEST_01_V
`define VGA_TEST_01_V

`include "directives.v"

module vga_test_01 (
    input       [9:0] column,
    input       [9:0] row,
    output wire [3:0] green,
    output wire [3:0] red,
    output wire [3:0] blue
);

  assign red = (row < 480 && column < 213) ? 4'b1111 : 4'b0000;
  assign
      green = (row < 480 && column >= 213 && column < 426) ? 4'b1111 : 4'b0000;
  assign
      blue = (row < 480 && column >= 426 && column < 640) ? 4'b1111 : 4'b0000;

endmodule

`endif
