`ifndef AXI_ARBITER_V
`define AXI_ARBITER_V

`include "directives.sv"

`include "arbiter.sv"
`include "sticky_bit.sv"

module axi_arbiter #(
    parameter  NUM_M          = 2,
    parameter  SEL_BITS       = 1,
    parameter  AXI_ADDR_WIDTH = 20,
    localparam G_BITS         = $clog2(NUM_M + 1)
) (
    input logic axi_clk,
    input logic axi_resetn,

    // address selector: this is the mux for the subordinate corresponding
    // to the lower SEL_BITS of in_axi_awaddr and in_axi_araddr
    input logic [SEL_BITS-1:0] a_sel,

    // Grants
    output logic [G_BITS-1:0] rg_req,
    output logic [G_BITS-1:0] wg_req,

    output logic [G_BITS-1:0] rg_resp,
    output logic [G_BITS-1:0] wg_resp,

    // manager ready/valid signals used to arbitrate
    input logic [NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_awaddr,
    input logic [NUM_M-1:0]                     in_axi_awvalid,
    input logic [NUM_M-1:0]                     in_axi_awready,
    input logic [NUM_M-1:0]                     in_axi_wvalid,
    input logic [NUM_M-1:0]                     in_axi_wready,
    input logic [NUM_M-1:0]                     in_axi_bvalid,
    input logic [NUM_M-1:0]                     in_axi_bready,
    input logic [NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_araddr,
    input logic [NUM_M-1:0]                     in_axi_arvalid,
    input logic [NUM_M-1:0]                     in_axi_arready,
    input logic [NUM_M-1:0]                     in_axi_rvalid,
    input logic [NUM_M-1:0]                     in_axi_rready
);
  localparam M_BITS = $clog2(NUM_M);

  //
  // Channels that want a grant
  //
  logic [NUM_M-1:0]               rg_want;
  logic [NUM_M-1:0]               wg_want;

  logic [NUM_M-1:0][SEL_BITS-1:0] in_axi_araddr_low;
  logic [NUM_M-1:0][SEL_BITS-1:0] in_axi_awaddr_low;

  genvar i;
  generate
    for (i = 0; i < NUM_M; i++) begin : gen_want
      assign in_axi_araddr_low[i] = in_axi_araddr[i][SEL_BITS-1:0];
      assign rg_want[i] = (in_axi_arvalid[i] && in_axi_araddr_low[i] == a_sel);

      assign in_axi_awaddr_low[i] = in_axi_awaddr[i][SEL_BITS-1:0];
      assign wg_want[i] = (in_axi_awvalid[i] && in_axi_awaddr_low[i] == a_sel);
    end
  endgenerate

  //
  // Txn acceptance and completion
  //

  // reads
  logic r_req_accepted;
  assign r_req_accepted = (in_axi_arvalid[M_BITS'(rg_req)] &&
                           in_axi_arready[M_BITS'(rg_req)]);

  logic r_resp_accepted;
  assign r_resp_accepted = (in_axi_rvalid[M_BITS'(rg_resp)] &&
                            in_axi_rready[M_BITS'(rg_resp)]);

  // writes
  logic w_awdone;
  logic w_wdone;
  logic w_req_accepted;
  assign w_req_accepted = w_awdone && w_wdone;

  logic w_resp_accepted;
  assign w_resp_accepted = (in_axi_bvalid[M_BITS'(wg_resp)] &&
                            in_axi_bready[M_BITS'(wg_resp)]);

  sticky_bit sticky_awdone (
      .clk(axi_clk),
      .reset(~axi_resetn),
      .in(in_axi_awvalid[M_BITS'(wg_req)] && in_axi_awready[M_BITS'(wg_req)]),
      .out(w_awdone),
      .clear(w_req_accepted)
  );

  sticky_bit sticky_wdone (
      .clk  (axi_clk),
      .reset(~axi_resetn),
      .in   (in_axi_wvalid[M_BITS'(wg_req)] && in_axi_wready[M_BITS'(wg_req)]),
      .out  (w_wdone),
      .clear(w_req_accepted)
  );

  // reads
  arbiter #(
      .NUM_M(NUM_M)
  ) r_arbiter (
      .clk          (axi_clk),
      .rst_n        (axi_resetn),
      .g_want       (rg_want),
      .req_accepted (r_req_accepted),
      .resp_accepted(r_resp_accepted),
      .g_req        (rg_req),
      .g_resp       (rg_resp)
  );

  // writes
  arbiter #(
      .NUM_M(NUM_M)
  ) w_arbiter (
      .clk          (axi_clk),
      .rst_n        (axi_resetn),
      .g_want       (wg_want),
      .req_accepted (w_req_accepted),
      .resp_accepted(w_resp_accepted),
      .g_req        (wg_req),
      .g_resp       (wg_resp)
  );

endmodule

`endif
