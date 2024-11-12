`include "testing.sv"
`include "txn_done.sv"

module txn_done_tb;
  logic clk;
  logic reset;
  logic valid;
  logic ready;
  logic clear;
  logic done;

  txn_done dut (
      .clk  (clk),
      .reset(reset),
      .valid(valid),
      .ready(ready),
      .clear(clear),
      .done (done)
  );

  `TEST_SETUP(txn_done_tb)

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize inputs
    reset = 0;
    valid = 0;
    ready = 0;
    clear = 0;

    // Reset sequence
    @(posedge clk);
    reset = 1;
    @(posedge clk);
    reset = 0;
    @(posedge clk);

    // Test case 1: Basic handshake
    `ASSERT_EQ(done, 0);
    valid = 1;
    ready = 1;
    @(posedge clk);
    `ASSERT_EQ(done, 1);

    // Test case 2: Done stays high after handshake
    valid = 0;
    ready = 0;
    @(posedge clk);
    `ASSERT_EQ(done, 1);

    // Test case 3: Clear resets done
    clear = 1;
    @(posedge clk);
    `ASSERT_EQ(done, 0);
    clear = 0;
    @(posedge clk);

    // Test case 4: Reset behavior
    valid = 1;
    ready = 1;
    reset = 1;
    @(posedge clk);
    // Should be 1 due to combinatorial path
    `ASSERT_EQ(done, 1);
    @(posedge clk);
    // Still 1 due to combinatorial path even though ff was reset
    `ASSERT_EQ(done, 1);
    reset = 1;
    valid = 0;
    ready = 0;
    @(posedge clk);
    // Now 0 since no comb path and ff was reset
    `ASSERT_EQ(done, 0);
    @(posedge clk);

    // Test case 5: No done assertion without both valid and ready
    valid = 1;
    ready = 0;
    @(posedge clk);
    `ASSERT_EQ(done, 0);
    valid = 0;
    ready = 1;
    @(posedge clk);
    `ASSERT_EQ(done, 0);

    // Test case 6: Multiple cycles of valid/ready
    valid = 1;
    ready = 1;
    @(posedge clk);
    `ASSERT_EQ(done, 1);
    @(posedge clk);
    `ASSERT_EQ(done, 1);

    $finish;
  end
endmodule
