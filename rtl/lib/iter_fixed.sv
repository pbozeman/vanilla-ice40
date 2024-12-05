`ifndef ITER_FIXED_V
`define ITER_FIXED_V
`include "directives.sv"
`include "counter_fixed.sv"

module iter_fixed #(
    parameter  MAX_VALUE = 15,
    localparam WIDTH     = $clog2(MAX_VALUE)
) (
    input  logic             clk,
    input  logic             reset,
    input  logic             inc,
    output logic [WIDTH-1:0] val,
    output logic             done
);
  localparam [WIDTH-1:0] MAX_COUNT = WIDTH'(MAX_VALUE);

  counter_fixed #(
      .MAX_VALUE(MAX_VALUE)
  ) i (
      .clk   (clk),
      .reset (reset),
      .enable(inc),
      .count (val)
  );

  assign done = (val == MAX_COUNT);

endmodule
`endif
