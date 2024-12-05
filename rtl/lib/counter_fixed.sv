`ifndef COUNTER_FIXED_V
`define COUNTER_FIXED_V

`include "directives.sv"

module counter_fixed #(
    parameter MAX_VALUE = 15,
    parameter WIDTH     = $clog2(MAX_VALUE + 1)
) (
    input  logic             clk,
    input  logic             reset,
    input  logic             enable,
    output logic [WIDTH-1:0] count
);
  // Define maximum value with proper width
  localparam [WIDTH-1:0] MAX_COUNT = WIDTH'(MAX_VALUE);

  initial begin
    count = '0;
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      count <= '0;
    end else if (enable) begin
      if (count == MAX_COUNT) begin
        count <= '0;
      end else begin
        count <= count + 1'b1;
      end
    end
  end

endmodule

`endif
