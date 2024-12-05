`ifndef COUNTER_V
`define COUNTER_V

`include "directives.sv"

module counter #(
    parameter WIDTH = 4
) (
    input  logic             clk,
    input  logic             reset,
    input  logic             enable,
    output logic [WIDTH-1:0] count
);
  always_ff @(posedge clk) begin
    if (reset) begin
      count <= 0;
    end else if (enable) begin
      count <= count + 1;
    end
  end

endmodule
`endif
