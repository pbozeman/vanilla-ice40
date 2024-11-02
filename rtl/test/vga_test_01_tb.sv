`include "testing.sv"

`include "vga_sync.sv"
`include "vga_test_01.sv"

// verilator lint_off UNUSEDSIGNAL

module vga_test_01_tb;
  localparam COLUMN_BITS = $clog2(`VGA_MODE_H_WHOLE_LINE);
  localparam ROW_BITS = $clog2(`VGA_MODE_V_WHOLE_FRAME);

  logic                   clk = 1'b0;
  logic                   reset = 1'b0;
  logic                   visible;
  logic                   hsync;
  logic                   vsync;
  logic [COLUMN_BITS-1:0] column;
  logic [   ROW_BITS-1:0] row;
  logic [            3:0] red;
  logic [            3:0] green;
  logic [            3:0] blue;

  // TODO: add enable tests
  logic                   enable = 1'b1;

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

  // mode specific clock
  initial begin
    clk = 0;
    forever #`VGA_MODE_TB_PIXEL_CLK clk = ~clk;
  end

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

