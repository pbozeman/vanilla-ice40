`ifndef PIN_WALKER_V
`define PIN_WALKER_V

`include "directives.sv"

module pin_walker #(
    parameter integer NUM_PINS      = 8,
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer DIVISOR       = 4
) (
    input  logic                clk,
    output logic [NUM_PINS-1:0] pins
);

  localparam DELAY = CLOCK_FREQ_HZ / DIVISOR;

  logic [$clog2(NUM_PINS)-1:0] pin_idx = 0;
  logic [   $clog2(DELAY)-1:0] counter = 0;

  always @(posedge clk) begin
    if (counter < DELAY - 1) begin
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

  assign pins = (1 << pin_idx);

endmodule

`endif
