`ifndef CDC_SYNC2_V
`define CDC_SYNC2_V

`include "directives.v"

//
// sync2 from
// https://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
//

// sync signal to different clock domain
module cdc_sync2 #(
    parameter WIDTH = 1
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q = 0
);

  // 1st stage ff output
  reg [WIDTH-1:0] q1 = 0;

  always @(posedge clk) begin
    if (!rst_n) begin
      q  <= 0;
      q1 <= 0;
    end else begin
      {q, q1} <= {q1, d};
    end
  end
endmodule

`endif
