// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module bit_reverser #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : reverse_bits
      assign out[i] = in[WIDTH-1-i];
    end
  endgenerate

endmodule
