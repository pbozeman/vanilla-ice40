`include "testing.sv"

`include "fb_addr.sv"
`include "vga_mode.sv"

module fb_addr_tb;
  localparam FB_WIDTH = `VGA_MODE_H_VISIBLE;
  localparam FB_HEIGHT = `VGA_MODE_V_VISIBLE;
  localparam ADDR_BITS = 20;
  localparam FB_X_BITS = $clog2(FB_WIDTH);
  localparam FB_Y_BITS = $clog2(FB_HEIGHT);

  logic                 clk = 0;
  logic [FB_X_BITS-1:0] fb_x;
  logic [FB_Y_BITS-1:0] fb_y;
  logic [ADDR_BITS-1:0] fb_addr;

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
    `ASSERT_EQ(fb_addr, FB_WIDTH);

    fb_x = 1;
    fb_y = 1;
    `TICK(clk);
    `ASSERT_EQ(fb_addr, FB_WIDTH + 1);

    $finish;
  end

endmodule
