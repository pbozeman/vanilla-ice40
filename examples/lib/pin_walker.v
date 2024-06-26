// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module pin_walker #(
    parameter integer NUM_PINS = 8,
    parameter integer CLOCK_FREQ_HZ = 100_000_000
) (
    input wire clk_i,
    output wire [NUM_PINS-1:0] pins_o
);

  localparam HALF_SECOND = CLOCK_FREQ_HZ / 2;

  reg [$clog2(NUM_PINS)-1:0] pin_idx = 0;
  reg [$clog2(HALF_SECOND)-1:0] counter = 0;

  always @(posedge clk_i) begin
    if (counter < HALF_SECOND - 1) begin
      counter <= counter + 1;
    end else begin
      counter <= 0;
      if (pin_idx < NUM_PINS - 1) begin
        pin_idx <= pin_idx + 1;
      end else begin
        pin_idx <= 0;
      end
    end
  end

  assign pins_o = (1 << pin_idx);

endmodule
