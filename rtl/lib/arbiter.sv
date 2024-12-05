`ifndef ARBITER_V
`define ARBITER_V

`include "directives.sv"

`include "sync_fifo.sv"

//
// Arbiter that issues grants from Managers to a Subordinate.
//
// Managers are selected with a modified priority encoding, with bit 0 as the
// highest pri.
//
// Request and response grants are tracked separately and released when
// the transaction is accepted (i.e. valid/ready pair are both high.)
//
module arbiter #(
    parameter  NUM_M  = 2,
    localparam G_BITS = $clog2(NUM_M + 1)
) (
    input logic clk,
    input logic rst_n,

    // bitmask of managers wanting a grant
    input logic [NUM_M-1:0] g_want,

    // the request grant is released on req_accepted,
    // and the response grant is released on req_accepted
    input logic req_accepted,
    input logic resp_accepted,

    // the active_request and response container the manager granted
    // the respective bus. (The holder of the response grant previously
    // held the active_request. This enables pipelining.)
    output logic [G_BITS-1:0] g_req,
    output logic [G_BITS-1:0] g_resp
);

  logic [G_BITS-1:0] next_g_req;

  logic              req_idle;
  assign req_idle = g_req == NUM_M;

  always_comb begin
    next_g_req = NUM_M;

    if (!req_idle && !req_accepted) begin
      next_g_req = g_req;
    end else begin
      if (!fifo_w_full) begin
        for (int i = NUM_M; i >= 0; i--) begin
          // TODO: the logic can likely be optimized.
          //
          // The reason we can't currently grant back to the same m is that since
          // g_req is registered. If the txn is accepted in the same clock that
          // it is issued, the instantiating module won't see the valid signal
          // in time. By cutting off the caller, we are dropping valid to the sub
          // on their behalf, and the instantiator will see ready on the next
          // rising clock. This slows down a single caller to only being able
          // to issue a txn every other cycle, but that's currently fine as this is
          // being used with sram modules that can only run every other clock
          // anyway. Research skid buffers and see if they can help here.
          if (g_want[i] && G_BITS'(i) != g_req) begin
            next_g_req = G_BITS'(i);
          end
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      g_req <= NUM_M;
    end else begin
      g_req <= next_g_req;
    end
  end

  logic              fifo_w_full;
  logic              fifo_w_inc;
  logic [G_BITS-1:0] fifo_r_data;
  logic              fifo_r_empty;

  assign fifo_w_inc = req_accepted;

  assign g_resp     = fifo_r_empty ? NUM_M : fifo_r_data;

  // TODO: this is a significant contributor to the ltp of the axi_arbiter.
  // Consider a special case double entry fifo, or even a direct
  // implementation of passing the grant to the response custom to this
  // module.
  //
  // ADDR_SIZE needs to be 2 otherwise we get full backpressure when
  // pipelining.
  sync_fifo #(
      .DATA_WIDTH(G_BITS),
      .ADDR_SIZE (2)
  ) resp_fifo (
      .clk          (clk),
      .rst_n        (rst_n),
      .w_inc        (fifo_w_inc),
      .w_data       (g_req),
      .w_almost_full(),
      .w_full       (fifo_w_full),
      .r_inc        (resp_accepted),
      .r_data       (fifo_r_data),
      .r_empty      (fifo_r_empty)
  );

endmodule

`endif
