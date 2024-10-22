`include "testing.v"

`include "fb_addr.v"

module fb_addr_tb;
  localparam FB_WIDTH = 640;
  localparam FB_HEIGHT = 480;
  localparam ADDR_BITS = 20;
  localparam FB_X_BITS = $clog2(FB_WIDTH);
  localparam FB_Y_BITS = $clog2(FB_HEIGHT);

  reg                 clk = 0;
  reg [FB_X_BITS-1:0] fb_x;
  reg [FB_Y_BITS-1:0] fb_y;
  reg [ADDR_BITS-1:0] fb_addr;

  fb_addr #(
      .FB_WIDTH (FB_WIDTH),
      .FB_HEIGHT(FB_HEIGHT),
      .ADDR_BITS(ADDR_BITS)
  ) addr_inst (
      .clk (clk),
      .x   (fb_x),
      .y   (fb_y),
      .addr(fb_addr)
  );

  `TEST_SETUP(fb_addr_tb);

  initial begin
    forever #5 clk = ~clk;
  end

  initial begin
    fb_x = 0;
    fb_y = 0;
    `TICK(clk);
    `ASSERT_EQ(fb_addr, 0);

    fb_x = 1;
    fb_y = 0;
    `TICK(clk);
    `ASSERT_EQ(fb_addr, 1);

    fb_x = 0;
    fb_y = 1;
    `TICK(clk);
    `ASSERT_EQ(fb_addr, 640);

    fb_x = 1;
    fb_y = 1;
    `TICK(clk);
    `ASSERT_EQ(fb_addr, 641);

    $finish;
  end

endmodule
