`ifndef CDC_SYNC2_V
`define CDC_SYNC2_V

`include "directives.sv"

//
// sync2 from
// https://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
//

// sync signal to different clock domain
module cdc_sync2 #(
    parameter WIDTH = 1
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q = 0
);

  // 1st stage ff output
  logic [WIDTH-1:0] q1 = 0;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      q  <= 0;
      q1 <= 0;
    end else begin
      {q, q1} <= {q1, d};
    end
  end
endmodule

`endif
