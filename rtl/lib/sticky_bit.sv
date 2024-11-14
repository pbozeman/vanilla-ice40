`ifndef STICKY_BIT_V
`define STICKY_BIT_V

`include "directives.sv"

module sticky_bit (
    input  logic clk,
    input  logic reset,
    input  logic in,
    input  logic clear,
    output logic out
);

  logic sticky_ff = 0;

  always_comb begin
    out = sticky_ff || in;
  end

  // Sequential sticky storage
  always_ff @(posedge clk) begin
    if (reset) sticky_ff <= 0;
    else if (clear) sticky_ff <= 0;
    else if (in) sticky_ff <= 1;
  end

endmodule

`endif
