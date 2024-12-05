`ifndef COUNTER_V
`define COUNTER_V

`include "directives.sv"

module counter #(
    parameter WIDTH = 4
) (
    input  logic             clk,
    input  logic             reset,
    input  logic             enable,
    output logic [WIDTH-1:0] val
);
  always_ff @(posedge clk) begin
    if (reset) begin
      val <= 0;
    end else if (enable) begin
      val <= val + 1;
    end
  end

endmodule
`endif
