`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module pin_walker_tb;
  localparam NUM_PINS = 16;
  localparam CLOCK_FREQ_HZ = 10;

  reg clk = 1'b0;
  wire [NUM_PINS-1:0] pins;
  integer i;

  reg [NUM_PINS-1:0] expected;

  pin_walker #(
      .NUM_PINS(NUM_PINS),
      .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ)
  ) uut (
      .clk_i (clk),
      .pins_o(pins)
  );

  // clock generator
  always #1 clk = ~clk;

  initial begin
    $dumpfile(".build/pin_walker.vcd");
    $dumpvars(0, pin_walker_tb);

    for (i = 0; i < 32 * (CLOCK_FREQ_HZ / 2); i = i + 1) begin
      @(posedge clk);

      if (i % (CLOCK_FREQ_HZ / 2) == 0) begin
        expected = {NUM_PINS{1'b0}} | (1'b1 << ((i / (CLOCK_FREQ_HZ / 2)) % NUM_PINS));
        `ASSERT(pins == expected);
      end
    end

    $finish;
  end

endmodule
