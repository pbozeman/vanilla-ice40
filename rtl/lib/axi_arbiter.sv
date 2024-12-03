`ifndef AXI_ARBITER_V
`define AXI_ARBITER_V

`include "directives.sv"

`include "sync_fifo.sv"

//
// AXI-Lite arbiter that issues grants from Managers to a Subordinate.
//
// Managers are selected with a modified priority encoding, with bit 0 as the
// highest pri.
//
// Request and response grants are tracked separately and released when
// the transaction is accepted (i.e. valid/ready pair are both high.)
//
module axi_arbiter #(
    parameter  NUM_M  = 2,
    localparam G_BITS = $clog2(NUM_M + 1)
) (
    input logic axi_clk,
    input logic axi_resetn,

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
  logic              req_started;

  logic              req_idle;
  assign req_idle = g_req == NUM_M;

  always_comb begin
    next_g_req  = NUM_M;
    req_started = 1'b0;

    if (!req_idle && !req_accepted) begin
      next_g_req = g_req;
    end else begin
      for (int i = NUM_M; i >= 0; i--) begin
        if (g_want[i]) begin
          req_started = 1'b1;
          next_g_req  = G_BITS'(i);
        end
      end
    end
  end

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      g_req <= NUM_M;
    end else begin
      g_req <= next_g_req;
    end
  end

  logic              fifo_w_inc;
  logic [G_BITS-1:0] fifo_r_data;
  logic              fifo_r_empty;

  always_ff @(posedge axi_clk) begin
    fifo_w_inc <= req_started;
  end

  assign g_resp = fifo_r_empty ? NUM_M : fifo_r_data;

  sync_fifo #(
      .DATA_WIDTH(G_BITS),
      .ADDR_SIZE (3)
  ) resp_fifo (
      .clk          (axi_clk),
      .rst_n        (axi_resetn),
      .w_inc        (fifo_w_inc),
      .w_data       (g_req),
      .w_almost_full(),
      .w_full       (),
      .r_inc        (resp_accepted),
      .r_data       (fifo_r_data),
      .r_empty      (fifo_r_empty)
  );

endmodule

`endif
