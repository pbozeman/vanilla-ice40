`include "testing.sv"
`include "sticky_bit.sv"

module sticky_bit_tb;

  logic clk;
  logic reset;
  logic in;
  logic clear;
  logic out;

  sticky_bit uut (
      .clk  (clk),
      .reset(reset),
      .in   (in),
      .clear(clear),
      .out  (out)
  );

  `TEST_SETUP(sticky_bit_tb)

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    // Initialize inputs
    reset = 1;
    in    = 0;
    clear = 0;

    // Release reset and wait a few cycles
    @(posedge clk);
    reset = 0;
    repeat (2) @(posedge clk);
    `ASSERT_EQ(out, 0);

    // Test immediate response to input
    in = 1;
    @(posedge clk);
    `ASSERT_EQ(out, 1);

    // Test keeping the value after input goes low
    @(posedge clk);
    in = 0;
    `ASSERT_EQ(out, 1);

    // Verify it stays set
    repeat (3) @(posedge clk);
    `ASSERT_EQ(out, 1);

    // Test clearing the sticky bit
    @(posedge clk);
    clear = 1;
    @(posedge clk);
    clear = 0;
    @(posedge clk);
    `ASSERT_EQ(out, 0);

    // Verify immediate response after being cleared
    in = 1;
    @(posedge clk);
    `ASSERT_EQ(out, 1);
    @(posedge clk);
    in = 0;
    `ASSERT_EQ(out, 1);

    // Test reset while bit is set
    reset = 1;
    @(posedge clk);
    reset = 0;
    `ASSERT_EQ(out, 0);

    $finish;
  end

endmodule
