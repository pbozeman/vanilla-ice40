`ifndef ITER_V
`define ITER_V

`include "directives.sv"

// it's up to the caller to ensure that the n multiples of the inc value
// cleanly divides into max given the starting point, otherwise we'll jump
// right over max. While we could do val >= max as the last check, we could
// still jump over the WIDTH. (If this ever becomes needed, create a comb
// to compute next_val and add next_val < val to the last check as a check
// for overflow)

module iter #(
    parameter WIDTH   = 4,
    parameter INC_VAL = 1
) (
    input  logic             clk,
    input  logic             init,
    input  logic [WIDTH-1:0] init_val,
    input  logic [WIDTH-1:0] max_val,
    input  logic             inc,
    output logic [WIDTH-1:0] val,
    output logic             last
);
  logic [WIDTH-1:0] next_val;
  logic [WIDTH-1:0] max_val_r;

  assign next_val = val + INC_VAL;

  always_ff @(posedge clk) begin
    if (init) begin
      val       <= init_val;
      max_val_r <= max_val;
      last      <= (init_val == max_val);
    end else if (inc && !last) begin
      val  <= next_val;
      last <= (next_val == max_val_r);
    end
  end
endmodule
`endif
