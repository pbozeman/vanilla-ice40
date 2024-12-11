`include "testing.sv"

// maybe check the other modes sometime, but this should be fine.
`ifdef VGA_MODE_640_480_60

`include "vga_pixel_iter.sv"

module vga_pixel_iter_tb;
  localparam H_WHOLE_LINE = `VGA_MODE_H_WHOLE_LINE;
  localparam V_WHOLE_FRAME = `VGA_MODE_V_WHOLE_FRAME;

  logic       clk;
  logic       reset;
  logic [9:0] x;
  logic [9:0] y;

  // TODO: add enable tests and last tests
  vga_pixel_iter #(
      .H_WHOLE_LINE (H_WHOLE_LINE),
      .V_WHOLE_FRAME(V_WHOLE_FRAME)
  ) uut (
      .clk   (clk),
      .reset (reset),
      .inc   (1'b1),
      .x     (x),
      .y     (y),
      .x_last(),
      .y_last()
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  `TEST_SETUP(vga_pixel_iter_tb);

  initial begin
    // Reset
    @(posedge clk);
    reset = 1;
    @(posedge clk);
    reset = 1;
    @(posedge clk);

    #1;
    `ASSERT_EQ(x, 0);
    `ASSERT_EQ(y, 0);

    @(posedge clk);
    reset = 0;
    #1;
    `ASSERT_EQ(x, 0);
    `ASSERT_EQ(y, 0);

    @(posedge clk);
    #1;
    `ASSERT_EQ(x, 1);
    `ASSERT_EQ(y, 0);

    @(posedge clk);
    #1;
    `ASSERT_EQ(x, 2);
    `ASSERT_EQ(y, 0);

    // Advance to end of line
    repeat (797) @(posedge clk);
    #1;
    `ASSERT_EQ(x, 799);
    `ASSERT_EQ(y, 0);

    // Row should roll over
    @(posedge clk);
    #1;
    `ASSERT_EQ(x, 0);
    `ASSERT_EQ(y, 1);

    // Advance to next line
    repeat (800) @(posedge clk);
    #1;
    `ASSERT_EQ(x, 0);
    `ASSERT_EQ(y, 2);

    // Advance to next line
    repeat (522) repeat (800) @(posedge clk);
    #1;
    `ASSERT_EQ(x, 0);
    `ASSERT_EQ(y, 524);

    // Should advance to next frame
    repeat (800) @(posedge clk);
    #1;
    `ASSERT_EQ(x, 0);
    `ASSERT_EQ(y, 0);

    $finish;
  end
endmodule
`else
module vga_pixel_iter_tb;
endmodule
`endif

