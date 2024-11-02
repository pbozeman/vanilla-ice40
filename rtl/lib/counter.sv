`ifndef COUNTER_V
`define COUNTER_V

`include "directives.sv"

module counter #(
    parameter MAX_VALUE = 15,
    parameter WIDTH     = $clog2(MAX_VALUE)
) (
    input  logic             clk,
    input  logic             reset,
    input  logic             enable,
    output logic [WIDTH-1:0] count
);

  initial begin
    count = {WIDTH{1'b0}};
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      count <= 0;
    end else if (enable) begin
      if (count >= MAX_VALUE) begin
        count <= 0;
      end else begin
        count <= count + 1;
      end
    end
  end

endmodule

`endif
