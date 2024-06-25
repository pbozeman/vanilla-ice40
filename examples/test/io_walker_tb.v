`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module io_walker_tb;
  localparam NUM_PINS = 16;

  reg clk = 1'b0;

  wire [NUM_PINS-1:0] test_pins;
  reg [NUM_PINS-1:0] result_pins;
  wire error;

  integer i;
  reg [NUM_PINS-1:0] expected_pins;

  io_walker #(
      .NUM_PINS(NUM_PINS)
  ) uut (
      .clk_i(clk),
      .test_pins(test_pins),
      .result_pins(result_pins),
      .error_o(error)
  );

  // clock generator
  always #1 clk = ~clk;

  // Simulate the behavior of result_pins
  always @(*) begin
    // Assume result_pins should match test_pins
    result_pins = test_pins;

    // Continuously assign pin3 to pin4
    result_pins[3] = result_pins[2];
  end

  initial begin
    $dumpfile(".build/io_walker.vcd");
    $dumpvars(0, uut);

    for (i = 0; i < 32; i = i + 1) begin
      @(posedge clk);
      if (i % NUM_PINS == 3 || i % NUM_PINS == 4) begin
        `ASSERT(error);
      end else begin
        `ASSERT(!error);
      end
    end

    $finish;
  end

endmodule

