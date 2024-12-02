`include "testing.sv"

`include "pin_walker.sv"

module pin_walker_tb;
  localparam NUM_PINS = 16;
  localparam CLOCK_FREQ_HZ = 10;
  localparam DIVISOR = 4;

  logic                  clk = 1'b0;
  logic   [NUM_PINS-1:0] pins;
  integer                i;

  logic   [NUM_PINS-1:0] expected;

  pin_walker #(
      .NUM_PINS     (NUM_PINS),
      .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
      .DIVISOR      (DIVISOR)
  ) uut (
      .clk (clk),
      .pins(pins)
  );

  // clock generator
  always #1 clk <= ~clk;

  `TEST_SETUP(pin_walker_tb);

  // verilator lint_off WIDTHEXPAND
  initial begin
    for (i = 0; i < 32 * (CLOCK_FREQ_HZ / DIVISOR); i = i + 1) begin
      @(posedge clk);

      if (i % (CLOCK_FREQ_HZ / DIVISOR) == 0) begin
        expected = {NUM_PINS{1'b0}} |
            (1'b1 << ((i / (CLOCK_FREQ_HZ / DIVISOR)) % NUM_PINS));
        `ASSERT(pins == expected);
      end
    end
    // verilator lint_on WIDTHEXPAND

    $finish;
  end

endmodule
