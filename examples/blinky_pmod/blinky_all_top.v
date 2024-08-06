`include "directives.v"

`include "pin_walker.v"

module blinky_all_top #(
    parameter NUM_PINS = 96
) (
    input wire CLK,
    output wire [NUM_PINS-1:0] R_PMOD
);

  pin_walker #(
      .NUM_PINS(NUM_PINS)
  ) uut (
      .clk (CLK),
      .pins(R_PMOD)
  );

endmodule
