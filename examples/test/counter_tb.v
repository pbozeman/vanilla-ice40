`include "testing.v"

`include "counter.v"

module counter_tb;
  parameter MAX_VALUE = 250;
  parameter WIDTH = 8;

  reg clk;
  reg reset;
  reg enable;
  wire [WIDTH-1:0] count;

  counter #(
      .MAX_VALUE(MAX_VALUE)
  ) uut (
      .clk(clk),
      .reset(reset),
      .enable(enable),
      .count(count)
  );

  always begin
    forever #5 clk = ~clk;
    #1000;
  end

  `TEST_SETUP(counter_tb);

  initial begin
    clk = 0;
    reset = 0;
    enable = 0;

    // reset should be optional
    `ASSERT(count == 0);
    enable = 1;
    @(posedge clk);
    `ASSERT(count == 0);
    @(posedge clk);
    `ASSERT(count == 1);
    enable = 0;

    // Apply reset
    reset  = 1;
    @(posedge clk);
    `ASSERT(count == 0);
    reset = 0;
    @(posedge clk);
    `ASSERT(count == 0);

    // Enable counter and count
    enable = 1;
    `ASSERT(count == 0);

    @(posedge clk);
    `ASSERT(count == 1);

    @(posedge clk);
    `ASSERT(count == 2);

    repeat (248) @(posedge clk);
    `ASSERT(count == 250);

    // Wrap
    @(posedge clk);
    `ASSERT(count == 0);

    repeat (10) @(posedge clk);
    `ASSERT(count == 10);

    // Disable counter
    enable = 0;
    repeat (5) @(posedge clk);
    `ASSERT(count == 10);

    enable = 1;
    repeat (5) @(posedge clk);
    `ASSERT(count == 15);

    // Apply reset again
    reset = 1;
    @(posedge clk);
    `ASSERT(count == 0);
    @(posedge clk);
    `ASSERT(count == 0);
    @(posedge clk);
    `ASSERT(count == 0);
    reset = 0;
    repeat (5) @(posedge clk);
    `ASSERT(count == 5);

    $finish;
  end
endmodule

