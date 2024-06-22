`timescale 1ns / 1ps

module vga_test_01_tb;

  reg clk = 1'b0;
  reg reset = 1'b0;
  wire visible;
  wire hsync;
  wire vsync;
  wire [9:0] column;
  wire [9:0] row;
  wire [3:0] red;
  wire [3:0] green;
  wire [3:0] blue;

  vga vga_inst (
      .clk_i(clk),
      .reset_i(reset),
      .visible_o(visible),
      .hsync_o(hsync),
      .vsync_o(vsync),
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

  // clock generator
  always #1 clk = ~clk;

  initial begin
    $dumpfile(".build/vga_test_01.vcd");
    $dumpvars(0, vga_test_01_tb);

    // 3 frames
    repeat (3 * 800 * 600) @(posedge clk);
    $finish;
  end

endmodule

