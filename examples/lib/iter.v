// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module iter #(
    parameter integer MAX_VALUE = 16,
    parameter WIDTH = $clog2(MAX_VALUE + 1)
) (
    input wire clk,
    input wire reset,
    input wire next,
    output wire [WIDTH-1:0] val,
    output wire done
);

  counter #(
      .MAX_VALUE(MAX_VALUE)
  ) i (
      .clk(clk),
      .reset(reset),
      .enable(next),
      .count(val)
  );

  assign done = (val == MAX_VALUE);

endmodule

