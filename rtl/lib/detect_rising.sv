`ifndef DETECT_RISING_V
`define DETECT_RISING_V

`include "directives.sv"

module detect_rising (
    input  logic clk,
    input  logic signal,
    output logic detected
);
  logic signal_prev = 0;
  assign detected = signal & ~signal_prev;

  always @(posedge clk) begin
    signal_prev <= signal;
  end

endmodule

`endif
