`ifndef BIT_REVERSER_V
`define BIT_REVERSER_V

`include "directives.v"

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

`endif
