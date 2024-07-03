`include "testing.v"

module iter_tb;

  parameter MAX_VALUE = 10;
  parameter WIDTH = $clog2(MAX_VALUE + 1);

  reg              clk;
  reg              reset;
  reg              next;
  wire [WIDTH-1:0] val;
  wire             done;

  reg  [WIDTH-1:0] expected_val;

  iter #(
      .MAX_VALUE(MAX_VALUE)
  ) uut (
      .clk  (clk),
      .reset(reset),
      .next (next),
      .val  (val),
      .done (done)
  );

  always begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  `TEST_SETUP(iter_tb);

  initial begin
    reset = 1;
    next = 0;
    expected_val = 0;
    @(posedge clk);
    reset = 0;
    @(posedge clk);

    // Test initial state
    `ASSERT(val == 0);
    `ASSERT(done == 0);

    // Iterate through all values and wrap around
    repeat (MAX_VALUE + 2) begin
      next = 1;
      @(posedge clk);

      if (expected_val == MAX_VALUE) begin
        expected_val = 0;
      end else begin
        expected_val = expected_val + 1;
      end

      next = 0;
      @(posedge clk);

      `ASSERT(val == expected_val);
      if (val == MAX_VALUE) begin
        `ASSERT(done == 1);
      end else begin
        `ASSERT(done == 0);
      end

    end

    // Test reset
    reset = 1;
    @(posedge clk);
    reset = 0;
    @(posedge clk);
    `ASSERT(val == 0);
    `ASSERT(done == 0);

    $finish;
  end

endmodule
