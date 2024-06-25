// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

// We don't use the normal _i and _o suffixes here because they are confusing
// for this use case. What is important to keep clear are the pins that are
// under test, and the pins that are returning results. The pins returning
// results are typed as "input", but really, they are coming from solder
// bridge, or the lack there of, not from the caller.
module io_walker #(
    parameter integer NUM_PINS = 8
) (
    input wire clk_i,
    output reg [NUM_PINS-1:0] test_pins = 0,
    input wire [NUM_PINS-1:0] result_pins,
    output wire error_o
);

  reg [$clog2(NUM_PINS)-1:0] test_pin_idx = 0;

  always @(posedge clk_i) begin
    // walk around by bit shifting the active pin
    test_pins <= (1 << test_pin_idx);

    // increment the test_pin_idx, wrapping around if necessary
    if (test_pin_idx == NUM_PINS - 1) begin
      test_pin_idx <= 0;
    end else begin
      test_pin_idx <= test_pin_idx + 1;
    end
  end

  assign error_o = (result_pins !== test_pins);

endmodule
