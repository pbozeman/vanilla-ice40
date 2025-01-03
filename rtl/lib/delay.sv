`ifndef DELAY_MODULE_V
`define DELAY_MODULE_V

`include "directives.sv"

// FIXME: add a reset that sets values to 0. It's caused a bunch of issues in
// testing.
module delay #(
    parameter DELAY_CYCLES = 1,
    parameter WIDTH        = 1
) (
    input  logic             clk,
    input  logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out
);

  logic   [WIDTH-1:0] shift_reg[DELAY_CYCLES-1:0];

  integer             i;

  always_ff @(posedge clk) begin
    shift_reg[0] <= in;
    for (i = 1; i < DELAY_CYCLES; i = i + 1) begin
      shift_reg[i] <= shift_reg[i-1];
    end
    out <= shift_reg[DELAY_CYCLES-1];
  end

endmodule

`endif
