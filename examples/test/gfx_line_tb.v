`include "testing.v"
`include "gfx_line.v"

module gfx_line_tb;
  parameter FB_WIDTH = 640;
  parameter FB_HEIGHT = 480;
  localparam FB_X_BITS = $clog2(FB_WIDTH);
  localparam FB_Y_BITS = $clog2(FB_HEIGHT);

  reg                  clk;
  reg                  reset;
  reg                  enable;
  reg                  start;
  reg  [FB_X_BITS-1:0] x0;
  reg  [FB_Y_BITS-1:0] y0;
  reg  [FB_X_BITS-1:0] x1;
  reg  [FB_Y_BITS-1:0] y1;
  wire [FB_X_BITS-1:0] x;
  wire [FB_Y_BITS-1:0] y;
  wire                 done;

  gfx_line #(
      .FB_WIDTH (FB_WIDTH),
      .FB_HEIGHT(FB_HEIGHT)
  ) uut (
      .clk   (clk),
      .reset (reset),
      .enable(enable),
      .start (start),
      .x0    (x0),
      .y0    (y0),
      .x1    (x1),
      .y1    (y1),
      .x     (x),
      .y     (y),
      .done  (done)
  );

  `TEST_SETUP(gfx_line_tb)

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    reset  = 0;
    enable = 1;
    start  = 0;
    x0     = 0;
    y0     = 0;
    x1     = 0;
    y1     = 0;

    `TICK(clk);
    reset = 1;
    `TICK(clk);
    reset = 0;
    `TICK(clk);

    // Test case 1: Horizontal line right
    x0    = 10;
    y0    = 10;
    x1    = 20;
    y1    = 10;

    start = 1;
    `TICK(clk);
    start = 0;

    `TICK(clk);
    `TICK(clk);
    `ASSERT_EQ(x, 10);
    `ASSERT_EQ(y, 10);

    wait (done);
    `ASSERT_EQ(x, 20);
    `ASSERT_EQ(y, 10);

    // Test case 2: Vertical line down
    `TICK(clk);
    x0    = 15;
    y0    = 10;
    x1    = 15;
    y1    = 20;
    start = 1;
    `TICK(clk);
    start = 0;
    `TICK(clk);
    `TICK(clk);
    `ASSERT_EQ(x, 15);
    `ASSERT_EQ(y, 10);

    wait (done);
    `TICK(clk);
    `ASSERT_EQ(x, 15);
    `ASSERT_EQ(y, 20);

    // Test case 3: Diagonal line
    `TICK(clk);
    x0    = 100;
    y0    = 100;
    x1    = 110;
    y1    = 110;
    start = 1;
    `TICK(clk);
    start = 0;

    wait (done);
    `TICK(clk);
    `ASSERT_EQ(x, 110);
    `ASSERT_EQ(y, 110);

    // Test case 4: Test enable control
    `TICK(clk);
    x0     = 200;
    y0     = 200;
    x1     = 210;
    y1     = 200;
    enable = 0;
    start  = 1;
    `TICK(clk);
    start = 0;
    `TICK(clk);

    // Should stay at initial position when disabled
    repeat (5) `TICK(clk);
    `ASSERT_EQ(x, 200);
    `ASSERT_EQ(y, 200);

    enable = 1;
    wait (done);
    `ASSERT_EQ(x, 210);
    `ASSERT_EQ(y, 200);

    $finish;
  end
endmodule
