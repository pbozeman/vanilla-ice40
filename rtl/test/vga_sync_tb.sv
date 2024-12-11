`include "testing.sv"

// maybe check the other modes sometime, but this should be fine.
`ifdef VGA_MODE_640_480_60
`include "vga_mode.sv"
`include "vga_sync.sv"

module vga_sync_tb;
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

  logic       clk = 1'b0;
  logic       reset = 1'b0;
  logic       visible;
  logic       hsync;
  logic       vsync;
  logic [9:0] x;
  logic [9:0] y;

  logic [3:0] frames = 0;

  // TODO: add inc tests
  logic       inc = 1'b1;

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
  ) uut (
      .clk    (clk),
      .reset  (reset),
      .inc    (inc),
      .visible(visible),
      .hsync  (hsync),
      .vsync  (vsync),
      .x      (x),
      .y      (y)
  );

  // clock generator
  always #1 clk <= ~clk;

  `TEST_SETUP(vga_sync_tb);

  initial begin
    reset = 1;
    @(posedge clk);
    reset = 0;
    @(posedge clk);

    // 3 frames
    repeat (3 * H_WHOLE_LINE * V_WHOLE_FRAME) begin
      @(posedge clk);
    end

    // Make sure we actually did stuff
    @(negedge clk);
    `ASSERT_EQ(frames, 3);

    $finish;
  end

  // invariants
  always @(posedge clk) begin
    `ASSERT(x < 800)
    `ASSERT(y < 525)

    // visible should only be on for display area
    if (x < 640 && y < 480) begin
      `ASSERT(visible)
    end else begin
      `ASSERT(!visible)
    end

    // vsync should only be on for lines 490 and 491
    if (y == 490 || y == 491) begin
      // Low active
      `ASSERT(!vsync)
    end else begin
      `ASSERT(vsync)
    end

    // hsync test
    if (x >= 656 && x < 752) begin
      `ASSERT(!hsync)
    end else begin
      `ASSERT(hsync);
    end

    if (y == 524 && x == 799) begin
      frames <= frames + 1;
    end
  end
endmodule
`else
module vga_sync_tb;
endmodule

`endif
