`ifndef TXN_DONE_V
`define TXN_DONE_V

`include "directives.sv"

// Done goes high in the cycle a transaction handshake is complete, but
// is remembered until cleared. This helps with waiting for completion
// of multiple events, e.g. AXI AW and W channels, without introducing
// a cycle of latency from the naive use of registers.
module txn_done (
    input  logic clk,
    input  logic reset,
    input  logic valid,
    input  logic ready,
    input  logic clear,
    output logic done
);
  logic done_comb;
  logic done_ff;

  assign done_comb = valid && ready;
  assign done      = done_comb || done_ff && !clear;

  always_ff @(posedge clk) begin
    if (reset || clear) begin
      done_ff <= 0;
    end else begin
      if (done_comb) begin
        done_ff <= 1;
      end
    end
  end
endmodule

`endif
