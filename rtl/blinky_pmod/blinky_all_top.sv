`include "directives.sv"

`include "pin_walker.sv"

module blinky_all_top #(
    parameter NUM_PINS = 96
) (
    input  logic                CLK,
    output logic [NUM_PINS-1:0] R_PMOD
);

  pin_walker #(
      .NUM_PINS(NUM_PINS)
  ) uut (
      .clk (CLK),
      .pins(R_PMOD)
  );

endmodule
