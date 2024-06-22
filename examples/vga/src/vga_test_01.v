module vga_test_01 (
    input [9:0] column_i,
    input [9:0] row_i,
    output wire [3:0] green_o,
    output wire [3:0] red_o,
    output wire [3:0] blue_o
);

  assign red_o   = (row_i < 480 && column_i < 213) ? 4'b1111 : 4'b0000;
  assign green_o = (row_i < 480 && column_i >= 213 && column_i < 426) ? 4'b1111 : 4'b0000;
  assign blue_o  = (row_i < 480 && column_i >= 426 && column_i < 640) ? 4'b1111 : 4'b0000;

endmodule
