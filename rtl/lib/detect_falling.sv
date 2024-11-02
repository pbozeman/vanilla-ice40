`ifndef DETECT_FALLLING_V
`define DETECT_FALLLING_V

`include "directives.sv"

// TODO: add tests for this.

module detect_falling (
    input  wire clk,
    input  wire signal,
    output wire detected
);
  reg signal_prev = 0;
  assign detected = signal_prev & ~signal;

  always @(posedge clk) begin
    signal_prev <= signal;
  end

endmodule

`endif
