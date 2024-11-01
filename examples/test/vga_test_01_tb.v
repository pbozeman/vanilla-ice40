`include "testing.v"

`include "vga_sync.v"
`include "vga_test_01.v"

// verilator lint_off UNUSEDSIGNAL

module vga_test_01_tb;
  localparam COLUMN_BITS = $clog2(`VGA_MODE_H_WHOLE_LINE);
  localparam ROW_BITS = $clog2(`VGA_MODE_V_WHOLE_FRAME);

  reg                    clk = 1'b0;
  reg                    reset = 1'b0;
  wire                   visible;
  wire                   hsync;
  wire                   vsync;
  wire [COLUMN_BITS-1:0] column;
  wire [   ROW_BITS-1:0] row;
  wire [            3:0] red;
  wire [            3:0] green;
  wire [            3:0] blue;

  // TODO: add enable tests
  wire                   enable = 1'b1;

  vga_sync vga_inst (
      .clk    (clk),
      .reset  (reset),
      .enable (enable),
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
  always #20 clk <= ~clk;

  `TEST_SETUP(vga_test_01_tb);

  initial begin
    // 3 frames
    repeat (3 * `VGA_MODE_H_WHOLE_LINE * `VGA_MODE_V_WHOLE_FRAME) begin
      @(posedge clk);
    end
    $finish;
  end

endmodule

// verilator lint_on UNUSEDSIGNAL

