`ifndef ADC_XY_V
`define ADC_XY_V

`include "directives.v"

`include "cdc_fifo.v"

// Sample the ADC bits on the ADC clock and ship the result to the main clock
// domain via a cdc_fifo.

module adc_xy #(
    parameter DATA_BITS = 10
) (
    input wire clk,
    input wire adc_clk,
    input wire reset,

    input wire [DATA_BITS-1:0] adc_x_bus,
    input wire [DATA_BITS-1:0] adc_y_bus,

    output wire [DATA_BITS-1:0] adc_x,
    output wire [DATA_BITS-1:0] adc_y
);
  localparam FIFO_WIDTH = DATA_BITS * 2;

  wire                  w_rst_n;
  wire                  w_inc;
  wire                  w_full;
  wire [FIFO_WIDTH-1:0] w_data;

  wire                  r_rst_n;
  wire                  r_inc;
  wire                  r_empty;
  wire [FIFO_WIDTH-1:0] r_data;

  assign w_data         = {adc_x_bus, adc_y_bus};
  assign {adc_x, adc_y} = r_data;

  // Just blast data in/out without checking since the ADC isn't going
  // to stop for us. On the other hand, we might want to have an enable
  // for the reader at some point and let some results buffer up in the
  // fifo. For now, just send it.
  cdc_fifo #(FIFO_WIDTH) fifo (
      .w_clk  (adc_clk),
      .w_rst_n(w_rst_n),
      .w_inc  (w_inc),
      .w_data (w_data),
      .w_full (w_full),
      .r_clk  (clk),
      .r_rst_n(r_rst_n),
      .r_inc  (r_inc),
      .r_empty(r_empty),
      .r_data (r_data)
  );

  assign w_rst_n = ~reset;
  assign w_inc   = 1'b1;

  assign r_rst_n = ~reset;
  assign r_inc   = 1'b1;

endmodule

`endif
