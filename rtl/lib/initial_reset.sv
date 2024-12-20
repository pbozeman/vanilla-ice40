`ifndef INITIAL_RESET_V
`define INITIAL_RESET_V

`include "directives.sv"

module initial_reset #(
    parameter CYCLES = 15
) (
    input  logic clk,
    output logic reset
);
  logic [$clog2(CYCLES)-1:0] reset_counter = 0;

  always_ff @(posedge clk) begin
    if (reset_counter < CYCLES) begin
      reset_counter <= reset_counter + 1;
      reset         <= 1'b1;
    end else begin
      reset <= 1'b0;
    end
  end

endmodule

`endif
