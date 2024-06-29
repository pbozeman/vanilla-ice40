module blinky_all_top #(
    parameter NUM_PINS = 96
) (
    input wire CLK,
    output wire [NUM_PINS-1:0] PMOD_PINS
);

  pin_walker #(
      .NUM_PINS(NUM_PINS)
  ) uut (
      .clk (CLK),
      .pins(PMOD_PINS)
  );

endmodule
