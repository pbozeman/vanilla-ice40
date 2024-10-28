`ifndef ADC_XY_V
`define ADC_XY_V

`include "directives.v"

`include "cdc_fifo.v"

// For now, just pass the results through to some
// io pins and test with a logic analyzer or scope
module adc_xy #(
    parameter DATA_BITS = 10
) (
    input wire clk,
    input wire adc_clk,

    input  wire [DATA_BITS-1:0] y_data_bus,
    output wire [DATA_BITS-1:0] y_data
);

  reg  w_rst_n = 0;
  wire w_inc;
  wire w_full;

  reg  r_rst_n = 0;
  wire r_inc;
  wire r_empty;

  // Just blast data in/out without checking
  cdc_fifo #(DATA_BITS) fifo (
      .w_clk  (adc_clk),
      .w_rst_n(w_rst_n),
      .w_inc  (w_inc),
      .w_data (y_data_bus),
      .w_full (w_full),
      .r_clk  (clk),
      .r_rst_n(r_rst_n),
      .r_inc  (r_inc),
      .r_empty(r_empty),
      .r_data (y_data)
  );

  always @(posedge clk) begin
    w_rst_n <= 1;
    w_inc   <= 1;

    r_rst_n <= 1;
    r_inc   <= 1;
  end

endmodule

`endif
