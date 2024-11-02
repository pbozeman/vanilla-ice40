`ifndef DETECT_RISING_V
`define DETECT_RISING_V

`include "directives.v"

module detect_rising (
    input  wire clk,
    input  wire signal,
    output wire detected
);
  reg signal_prev = 0;
  assign detected = signal & ~signal_prev;

  always @(posedge clk) begin
    signal_prev <= signal;
  end

endmodule

`endif
