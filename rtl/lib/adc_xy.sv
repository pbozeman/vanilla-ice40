`ifndef ADC_XY_V
`define ADC_XY_V

`include "directives.sv"

`include "cdc_fifo.sv"

// Sample the ADC bits on the ADC clock and ship the result to the main clock
// domain via a cdc_fifo.

module adc_xy #(
    parameter DATA_BITS = 10
) (
    input logic clk,
    input logic adc_clk,
    input logic reset,

    input logic [DATA_BITS-1:0] adc_x_io,
    input logic [DATA_BITS-1:0] adc_y_io,

    output logic [DATA_BITS-1:0] adc_x,
    output logic [DATA_BITS-1:0] adc_y
);
  localparam FIFO_WIDTH = DATA_BITS * 2;

  logic                  w_rst_n;
  logic                  w_inc;
  logic [FIFO_WIDTH-1:0] w_data;
  // verilator lint_off UNUSEDSIGNAL
  logic                  w_full;
  logic                  w_almost_full;
  // verilator lint_on UNUSEDSIGNAL

  logic                  r_rst_n;
  logic                  r_inc;
  logic [FIFO_WIDTH-1:0] r_data;
  // verilator lint_off UNUSEDSIGNAL
  logic                  r_empty;
  // verilator lint_on UNUSEDSIGNAL

  assign w_data         = {adc_x_io, adc_y_io};
  assign {adc_x, adc_y} = r_data;

  // Just blast data in/out without checking since the ADC isn't going
  // to stop for us. On the other hand, we might want to have an enable
  // for the reader at some point and let some results buffer up in the
  // fifo. For now, just send it.
  cdc_fifo #(
      .DATA_WIDTH(FIFO_WIDTH),
      .ADDR_SIZE (3)
  ) fifo (
      .w_clk        (adc_clk),
      .w_rst_n      (w_rst_n),
      .w_inc        (w_inc),
      .w_data       (w_data),
      .w_full       (w_full),
      .w_almost_full(w_almost_full),
      .r_clk        (clk),
      .r_rst_n      (r_rst_n),
      .r_inc        (r_inc),
      .r_empty      (r_empty),
      .r_data       (r_data)
  );

  assign w_rst_n = ~reset;
  assign w_inc   = 1'b1;

  assign r_rst_n = ~reset;
  assign r_inc   = 1'b1;

endmodule

`endif
