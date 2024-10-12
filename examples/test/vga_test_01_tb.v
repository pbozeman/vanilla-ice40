`include "testing.v"

`include "vga_sync.v"
`include "vga_test_01.v"

// verilator lint_off UNUSEDSIGNAL

module vga_test_01_tb;

  reg        clk = 1'b0;
  reg        reset = 1'b0;
  wire       visible;
  wire       hsync;
  wire       vsync;
  wire [9:0] column;
  wire [9:0] row;
  wire [3:0] red;
  wire [3:0] green;
  wire [3:0] blue;

  vga_sync vga_inst (
      .clk    (clk),
      .reset  (reset),
      .visible(visible),
      .hsync  (hsync),
      .vsync  (vsync),
      .column (column),
      .row    (row)
  );

  vga_test_01 vga_pattern (
      .column(column),
      .row   (row),
      .red   (red),
      .green (green),
      .blue  (blue)
  );

  // clock generator
  always #1 clk <= ~clk;

  `TEST_SETUP(vga_test_01_tb);

  initial begin
    // 3 frames
    repeat (3 * 800 * 600) @(posedge clk);
    $finish;
  end

endmodule

// verilator lint_on UNUSEDSIGNAL

