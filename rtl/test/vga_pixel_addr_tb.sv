`include "testing.sv"

// maybe check the other modes sometime, but this should be fine.
`ifdef VGA_MODE_640_480_60

`include "vga_pixel_addr.sv"

module vga_pixel_addr_tb;
  localparam H_WHOLE_LINE = `VGA_MODE_H_WHOLE_LINE;
  localparam V_WHOLE_FRAME = `VGA_MODE_V_WHOLE_FRAME;

  logic       clk;
  logic       reset;
  logic [9:0] column;
  logic [9:0] row;

  // TODO: add enable tests
  logic       enable = 1'b1;

  vga_pixel_addr #(
      .H_WHOLE_LINE (H_WHOLE_LINE),
      .V_WHOLE_FRAME(V_WHOLE_FRAME)
  ) uut (
      .clk   (clk),
      .reset (reset),
      .enable(enable),
      .column(column),
      .row   (row)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  `TEST_SETUP(vga_pixel_addr_tb);

  initial begin
    // Reset
    @(posedge clk);
    reset = 1;
    @(posedge clk);
    reset = 1;
    @(posedge clk);

    #1;
    `ASSERT_EQ(column, 0);
    `ASSERT_EQ(row, 0);

    @(posedge clk);
    reset = 0;
    #1;
    `ASSERT_EQ(column, 0);
    `ASSERT_EQ(row, 0);

    @(posedge clk);
    #1;
    `ASSERT_EQ(column, 1);
    `ASSERT_EQ(row, 0);

    @(posedge clk);
    #1;
    `ASSERT_EQ(column, 2);
    `ASSERT_EQ(row, 0);

    // Advance to end of line
    repeat (797) @(posedge clk);
    #1;
    `ASSERT_EQ(column, 799);
    `ASSERT_EQ(row, 0);

    // Row should roll over
    @(posedge clk);
    #1;
    `ASSERT_EQ(column, 0);
    `ASSERT_EQ(row, 1);

    // Advance to next line
    repeat (800) @(posedge clk);
    #1;
    `ASSERT_EQ(column, 0);
    `ASSERT_EQ(row, 2);

    // Advance to next line
    repeat (522) repeat (800) @(posedge clk);
    #1;
    `ASSERT_EQ(column, 0);
    `ASSERT_EQ(row, 524);

    // Should advance to next frame
    repeat (800) @(posedge clk);
    #1;
    `ASSERT_EQ(column, 0);
    `ASSERT_EQ(row, 0);

    $finish;
  end
endmodule
`else
module vga_pixel_addr_tb;
endmodule
`endif

