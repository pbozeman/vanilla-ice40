`include "testing.v"

`include "iter.v"

module iter_tb;

  parameter MAX_VALUE = 10;
  parameter WIDTH = $clog2(MAX_VALUE + 1);

  reg              clk;
  reg              reset;
  reg              inc;
  wire [WIDTH-1:0] val;
  wire             done;

  reg  [WIDTH-1:0] expected_val;

  iter #(
      .MAX_VALUE(MAX_VALUE)
  ) uut (
      .clk  (clk),
      .reset(reset),
      .inc  (inc),
      .val  (val),
      .done (done)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  `TEST_SETUP(iter_tb);

  initial begin
    reset        = 1;
    inc          = 0;
    expected_val = 0;
    @(posedge clk);
    @(negedge clk);
    reset = 0;
    @(posedge clk);
    @(negedge clk);

    // Test initial state
    `ASSERT(val == 0);
    `ASSERT(done == 0);

    // Iterate through all values and wrap around
    repeat (MAX_VALUE + 2) begin
      inc = 1;
      @(posedge clk);
      @(negedge clk);

      if (expected_val == MAX_VALUE) begin
        expected_val = 0;
      end else begin
        expected_val = expected_val + 1;
      end

      inc = 0;
      @(posedge clk);
      @(negedge clk);

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
    @(negedge clk);
    reset = 0;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(val == 0);
    `ASSERT(done == 0);

    $finish;
  end

endmodule
