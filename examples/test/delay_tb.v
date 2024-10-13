`include "testing.v"

`include "delay.v"

module delay_tb;

  parameter DELAY_CYCLES = 3;

  reg  clk;
  reg  in;
  wire out;

  delay #(
      .DELAY_CYCLES(DELAY_CYCLES)
  ) dut (
      .clk(clk),
      .in (in),
      .out(out)
  );

  `TEST_SETUP(delay_tb)

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    in = 0;
    repeat (2) @(posedge clk);

    in = 1;
    @(posedge clk);
    in = 0;

    repeat (DELAY_CYCLES + 1) begin
      @(posedge clk);
      @(negedge clk);
      `ASSERT(out === in)
    end

    in = 1;
    repeat (DELAY_CYCLES) begin
      @(posedge clk);
      @(negedge clk);
      `ASSERT(out === 0)
    end
    @(posedge clk);
    @(negedge clk);
    `ASSERT(out === 1)

    repeat (3) @(posedge clk);

    $finish;
  end

endmodule
