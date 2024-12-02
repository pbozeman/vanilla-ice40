`ifndef PIN_WALKER_V
`define PIN_WALKER_V

`include "directives.sv"

module pin_walker #(
    parameter NUM_PINS      = 8,
    parameter CLOCK_FREQ_HZ = 100_000_000,
    parameter DIVISOR       = 4
) (
    input  logic                clk,
    output logic [NUM_PINS-1:0] pins
);
  // Calculate the necessary widths using local parameters
  localparam DELAY = CLOCK_FREQ_HZ / DIVISOR;
  localparam PIN_IDX_WIDTH = $clog2(NUM_PINS);
  localparam COUNTER_WIDTH = $clog2(DELAY);

  // Declare registers with explicit widths
  logic [PIN_IDX_WIDTH-1:0] pin_idx = '0;
  logic [COUNTER_WIDTH-1:0] counter = '0;

  localparam PIN_IDX_MAX = PIN_IDX_WIDTH'(NUM_PINS - 1);
  localparam COUNTER_MAX = COUNTER_WIDTH'(DELAY - 1);

  always_ff @(posedge clk) begin
    if (counter < COUNTER_MAX) begin
      counter <= counter + 1'b1;
    end else begin
      counter <= '0;
      if (pin_idx < PIN_IDX_MAX) begin
        pin_idx <= pin_idx + 1'b1;
      end else begin
        pin_idx <= '0;
      end
    end
  end

  assign pins = (1'b1 << pin_idx);

endmodule
`endif
