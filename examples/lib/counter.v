`ifndef COUNTER_V
`define COUNTER_V

`include "directives.v"

module counter #(
    parameter MAX_VALUE = 15,
    parameter WIDTH     = $clog2(MAX_VALUE + 1)
) (
    input  wire             clk,
    input  wire             reset,
    input  wire             enable,
    output reg  [WIDTH-1:0] count
);

  initial begin
    count = {WIDTH{1'b0}};
  end

  always @(posedge clk) begin
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
