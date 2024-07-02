// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module counter #(
    parameter MAX_VALUE = 16,
    parameter WIDTH = $clog2(MAX_VALUE + 1)
) (
    input clk,
    input reset,
    input enable,
    output reg [WIDTH-1:0] count
);

  initial begin
    count = {WIDTH{1'b0}};
  end

  always @(posedge clk or posedge reset) begin
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
