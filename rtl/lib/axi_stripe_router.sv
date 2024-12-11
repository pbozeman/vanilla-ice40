`ifndef AXI_STRIPE_ROUTER_V
`define AXI_STRIPE_ROUTER_V

`include "directives.sv"
`include "sync_fifo.sv"

//
// Routes axi requests from a single manager to a subordinate based on addr.
//
module axi_stripe_router #(
    parameter  SEL_BITS       = 2,
    parameter  AXI_ADDR_WIDTH = 20,
    localparam R_BITS         = SEL_BITS + 1
) (
    input  logic                      axi_clk,
    input  logic                      axi_resetn,
    // verilator lint_off UNUSEDSIGNAL
    input  logic [AXI_ADDR_WIDTH-1:0] axi_addr,
    // verilator lint_on UNUSEDSIGNAL
    input  logic                      axi_avalid,
    input  logic                      req_accepted,
    input  logic                      resp_accepted,
    output logic [        R_BITS-1:0] req,
    output logic [        R_BITS-1:0] resp
);
  localparam CHANNEL_IDLE = {R_BITS{1'b1}};

  logic txn_started;
  assign txn_started = req != CHANNEL_IDLE;

  logic [  R_BITS-1:0] next_req;
  logic [SEL_BITS-1:0] axi_addr_low;

  assign axi_addr_low = axi_addr[SEL_BITS-1:0];

  always_comb begin
    next_req = CHANNEL_IDLE;
    if (txn_started && !req_accepted) begin
      next_req = req;
    end else begin
      if (axi_avalid) begin
        next_req = {1'b0, axi_addr_low};
      end
    end
  end

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      req <= CHANNEL_IDLE;
    end else begin
      req <= next_req;
    end
  end

  //
  // pass the selected req via a fifo to the response phase
  //
  logic [R_BITS-1:0] fifo_w_data;
  logic              fifo_w_inc;
  logic [R_BITS-1:0] fifo_r_data;
  logic              fifo_r_inc;
  logic              fifo_r_empty;

  assign fifo_w_data = req;
  assign fifo_w_inc  = req_accepted;
  assign fifo_r_inc  = resp_accepted;
  assign resp        = fifo_r_empty ? CHANNEL_IDLE : fifo_r_data;

  sync_fifo #(
      .DATA_WIDTH(R_BITS),
      .ADDR_SIZE (2)
  ) resp_fifo (
      .clk          (axi_clk),
      .rst_n        (axi_resetn),
      .w_inc        (fifo_w_inc),
      .w_data       (fifo_w_data),
      .w_full       (),
      .w_almost_full(),
      .r_inc        (fifo_r_inc),
      .r_data       (fifo_r_data),
      .r_empty      (fifo_r_empty)
  );
endmodule
`endif
