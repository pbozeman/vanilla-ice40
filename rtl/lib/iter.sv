`ifndef ITER_V
`define ITER_V

`include "directives.sv"

`include "counter.sv"

module iter #(
    parameter integer MAX_VALUE = 15,
    parameter         WIDTH     = $clog2(MAX_VALUE)
) (
    input  wire             clk,
    input  wire             reset,
    input  wire             inc,
    output wire [WIDTH-1:0] val,
    output wire             done
);

  counter #(
      .MAX_VALUE(MAX_VALUE)
  ) i (
      .clk   (clk),
      .reset (reset),
      .enable(inc),
      .count (val)
  );

  assign done = (val == MAX_VALUE);

endmodule

`endif
