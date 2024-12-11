`include "testing.sv"

`include "vga_sync.sv"
`include "vga_test_01.sv"

// verilator lint_off UNUSEDSIGNAL

module vga_test_01_tb;
  localparam H_VISIBLE = `VGA_MODE_H_VISIBLE;
  localparam H_FRONT_PORCH = `VGA_MODE_H_FRONT_PORCH;
  localparam H_SYNC_PULSE = `VGA_MODE_H_SYNC_PULSE;
  localparam H_BACK_PORCH = `VGA_MODE_H_BACK_PORCH;
  localparam H_WHOLE_LINE = `VGA_MODE_H_WHOLE_LINE;

  localparam V_VISIBLE = `VGA_MODE_V_VISIBLE;
  localparam V_FRONT_PORCH = `VGA_MODE_V_FRONT_PORCH;
  localparam V_SYNC_PULSE = `VGA_MODE_V_SYNC_PULSE;
  localparam V_BACK_PORCH = `VGA_MODE_V_BACK_PORCH;
  localparam V_WHOLE_FRAME = `VGA_MODE_V_WHOLE_FRAME;

  localparam col_BITS = $clog2(`VGA_MODE_H_WHOLE_LINE);
  localparam Y_BITS = $clog2(`VGA_MODE_V_WHOLE_FRAME);

  logic                clk = 1'b0;
  logic                reset = 1'b0;
  logic                visible;
  logic                hsync;
  logic                vsync;
  logic [col_BITS-1:0] x;
  logic [  Y_BITS-1:0] y;
  logic [         3:0] red;
  logic [         3:0] green;
  logic [         3:0] blue;

  // TODO: add inc tests
  logic                inc = 1'b1;

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
      .clk    (clk),
      .reset  (reset),
      .inc    (inc),
      .visible(visible),
      .hsync  (hsync),
      .vsync  (vsync),
      .x      (x),
      .y      (y)
  );

  vga_test_01 #(
      .H_VISIBLE   (H_VISIBLE),
      .H_WHOLE_LINE(H_WHOLE_LINE),

      .V_VISIBLE    (V_VISIBLE),
      .V_WHOLE_FRAME(V_WHOLE_FRAME)
  ) vga_pattern (
      .x    (x),
      .y    (y),
      .red  (red),
      .green(green),
      .blue (blue)
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

