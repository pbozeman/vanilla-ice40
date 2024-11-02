`ifndef GRAY_TO_BIN_V
`define GRAY_TO_BIN_V

`include "directives.sv"

module gray_to_bin #(
    parameter WIDTH = 4
) (
    input  wire [WIDTH-1:0] gray,
    output wire [WIDTH-1:0] bin
);

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_binary
      assign bin[i] = ^gray[WIDTH-1:i];
    end
  endgenerate

endmodule

`endif
