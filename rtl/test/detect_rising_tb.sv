`include "testing.sv"
`include "detect_rising.sv"

module detect_rising_tb;

  reg  clk;
  reg  signal;
  wire detected;

  detect_rising uut (
      .clk     (clk),
      .signal  (signal),
      .detected(detected)
  );

  `TEST_SETUP(detect_rising_tb)

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    signal = 0;

    // Test case 1: No change
    @(posedge clk);
    `ASSERT(detected === 1'b0)
    @(posedge clk);

    // Test case 2: Rising edge
    signal = 1;
    #1;
    `ASSERT(detected === 1'b1)

    // Test case 3: Continued high (but no longer on rising edge)
    @(posedge clk);
    #1;
    `ASSERT(detected === 1'b0)

    // Test case 4: Falling edge
    signal = 0;
    @(posedge clk);
    #1;
    `ASSERT(detected === 1'b0)

    // Test case 5: Another rising edge
    signal = 1;
    @(posedge clk);
    `ASSERT(detected === 1'b1)

    // Test case 6: Quick toggle
    signal = 0;
    @(posedge clk);
    signal = 1;
    @(posedge clk);
    `ASSERT(detected === 1'b1)

    $finish;
  end

endmodule
