`ifndef DETECT_FALLLING_V
`define DETECT_FALLLING_V

`include "directives.sv"

// TODO: add tests for this.

module detect_falling (
    input  logic clk,
    input  logic signal,
    output logic detected
);
  logic signal_prev = 0;
  assign detected = signal_prev & ~signal;

  always_ff @(posedge clk) begin
    signal_prev <= signal;
  end

endmodule

`endif
