// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module counter #(
    parameter MAX_VALUE = 16,
    parameter WIDTH = $clog2(MAX_VALUE + 1)
) (
    input clk_i,
    input reset_i,
    input enable_i,
    output reg [WIDTH-1:0] count_o
);

  initial begin
    count_o = {WIDTH{1'b0}};
  end

  always @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      count_o <= 0;
    end else if (enable_i) begin
      if (count_o >= MAX_VALUE) begin
        count_o <= 0;
      end else begin
        count_o <= count_o + 1;
      end
    end
  end
endmodule
