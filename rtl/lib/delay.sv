`ifndef DELAY_MODULE_V
`define DELAY_MODULE_V

`include "directives.sv"

module delay #(
    parameter DELAY_CYCLES = 1,
    parameter WIDTH        = 1
) (
    input  wire             clk,
    input  wire [WIDTH-1:0] in,
    output reg  [WIDTH-1:0] out
);

  reg     [WIDTH-1:0] shift_reg[DELAY_CYCLES-1:0];

  integer             i;

  always @(posedge clk) begin
    shift_reg[0] <= in;
    for (i = 1; i < DELAY_CYCLES; i = i + 1) begin
      shift_reg[i] <= shift_reg[i-1];
    end
    out <= shift_reg[DELAY_CYCLES-1];
  end

endmodule

`endif
