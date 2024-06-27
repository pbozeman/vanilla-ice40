module blinky_all_top #(
    parameter NUM_PINS = 96
) (
    input wire clk_i,
    output wire [NUM_PINS-1:0] PMOD_PINS
);

  pin_walker #(
      .NUM_PINS(NUM_PINS)
  ) uut (
      .clk_i (clk_i),
      .pins_o(PMOD_PINS)
  );

endmodule
