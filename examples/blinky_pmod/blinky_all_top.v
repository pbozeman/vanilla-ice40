`define PINS CD_PINS

module blinky_all_top #(
    parameter NUM_PINS = 8
) (
    input wire clk_i,
    output wire [NUM_PINS-1:0] `PINS
);

  pin_walker #(
      .NUM_PINS(NUM_PINS)
  ) uut (
      .clk_i (clk_i),
      .pins_o(`PINS)
  );

endmodule
