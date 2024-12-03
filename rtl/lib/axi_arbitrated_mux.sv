`ifndef AXI_ARBITRATED_MUX_V
`define AXI_ARBITRATED_MUX_V

`include "directives.sv"

`include "axi_arbiter.sv"
`include "sticky_bit.sv"

module axi_arbitrated_mux #(
    parameter  NUM_M          = 2,
    parameter  SEL_BITS       = 1,
    parameter  AXI_ADDR_WIDTH = 20,
    parameter  AXI_DATA_WIDTH = 16,
    localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    // address selector: this is the mux for the subordinate corresponding
    // to the lower SEL_BITS of in_axi_awaddr and in_axi_araddr
    input logic [SEL_BITS-1:0] a_sel,

    // AXI-Lite Input
    input  logic [NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_awaddr,
    input  logic [NUM_M-1:0]                     in_axi_awvalid,
    output logic [NUM_M-1:0]                     in_axi_awready,
    input  logic [NUM_M-1:0][AXI_DATA_WIDTH-1:0] in_axi_wdata,
    input  logic [NUM_M-1:0][AXI_STRB_WIDTH-1:0] in_axi_wstrb,
    input  logic [NUM_M-1:0]                     in_axi_wvalid,
    output logic [NUM_M-1:0]                     in_axi_wready,
    output logic [NUM_M-1:0][               1:0] in_axi_bresp,
    output logic [NUM_M-1:0]                     in_axi_bvalid,
    input  logic [NUM_M-1:0]                     in_axi_bready,
    input  logic [NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_araddr,
    input  logic [NUM_M-1:0]                     in_axi_arvalid,
    output logic [NUM_M-1:0]                     in_axi_arready,
    output logic [NUM_M-1:0][AXI_DATA_WIDTH-1:0] in_axi_rdata,
    output logic [NUM_M-1:0][               1:0] in_axi_rresp,
    output logic [NUM_M-1:0]                     in_axi_rvalid,
    input  logic [NUM_M-1:0]                     in_axi_rready,

    // Subordinate interface
    output logic [AXI_ADDR_WIDTH-1:0] out_axi_awaddr,
    output logic                      out_axi_awvalid,
    input  logic                      out_axi_awready,
    output logic [AXI_DATA_WIDTH-1:0] out_axi_wdata,
    output logic [AXI_STRB_WIDTH-1:0] out_axi_wstrb,
    output logic                      out_axi_wvalid,
    input  logic                      out_axi_wready,
    input  logic [               1:0] out_axi_bresp,
    input  logic                      out_axi_bvalid,
    output logic                      out_axi_bready,
    output logic [AXI_ADDR_WIDTH-1:0] out_axi_araddr,
    output logic                      out_axi_arvalid,
    input  logic                      out_axi_arready,
    input  logic [AXI_DATA_WIDTH-1:0] out_axi_rdata,
    input  logic [               1:0] out_axi_rresp,
    input  logic                      out_axi_rvalid,
    output logic                      out_axi_rready
);
  localparam G_BITS = $clog2(NUM_M + 1);

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
  assign r_req_accepted = out_axi_arvalid && out_axi_arready;

  logic r_resp_accepted;
  assign r_resp_accepted = out_axi_rvalid && out_axi_rready;

  // writes
  logic w_awdone;
  logic w_wdone;
  logic w_req_accepted;
  assign w_req_accepted = w_awdone && w_wdone;

  logic w_resp_accepted;
  assign w_resp_accepted = out_axi_bvalid && out_axi_bready;

  sticky_bit sticky_awdone (
      .clk  (axi_clk),
      .reset(~axi_resetn),
      .in   (out_axi_awvalid && out_axi_awready),
      .out  (w_awdone),
      .clear(w_req_accepted)
  );

  sticky_bit sticky_wdone (
      .clk  (axi_clk),
      .reset(~axi_resetn),
      .in   (out_axi_wvalid && out_axi_wready),
      .out  (w_wdone),
      .clear(w_req_accepted)
  );

  //
  // Grant arbitration
  //
  logic [G_BITS-1:0] rg_req;
  logic [G_BITS-1:0] wg_req;

  logic [G_BITS-1:0] rg_resp;
  logic [G_BITS-1:0] wg_resp;

  logic              rg_req_active;
  logic              rg_resp_active;
  logic              wg_req_active;
  logic              wg_resp_active;

  assign rg_req_active  = (rg_req != NUM_M);
  assign rg_resp_active = (rg_resp != NUM_M);
  assign wg_req_active  = (wg_req != NUM_M);
  assign wg_resp_active = (wg_resp != NUM_M);

  // reads
  axi_arbiter #(
      .NUM_M(NUM_M)
  ) r_arbiter (
      .axi_clk      (axi_clk),
      .axi_resetn   (axi_resetn),
      .g_want       (rg_want),
      .req_accepted (r_req_accepted),
      .resp_accepted(r_resp_accepted),
      .g_req        (rg_req),
      .g_resp       (rg_resp)
  );

  // writes
  axi_arbiter #(
      .NUM_M(NUM_M)
  ) w_arbiter (
      .axi_clk      (axi_clk),
      .axi_resetn   (axi_resetn),
      .g_want       (wg_want),
      .req_accepted (w_req_accepted),
      .resp_accepted(w_resp_accepted),
      .g_req        (wg_req),
      .g_resp       (wg_resp)
  );

  //
  // Muxing in->out
  //
  // TODO: review the resource usage of timing of this approach of muxing
  // a null value into bits being muxed, v.s. something like 
  //   enable ? signal[mux] : '0;
  logic [NUM_M:0][AXI_ADDR_WIDTH-1:0] mux_axi_araddr;
  logic [NUM_M:0]                     mux_axi_arvalid;
  logic [NUM_M:0]                     mux_axi_rready;
  logic [NUM_M:0][AXI_ADDR_WIDTH-1:0] mux_axi_awaddr;
  logic [NUM_M:0]                     mux_axi_awvalid;
  logic [NUM_M:0][AXI_DATA_WIDTH-1:0] mux_axi_wdata;
  logic [NUM_M:0][AXI_STRB_WIDTH-1:0] mux_axi_wstrb;
  logic [NUM_M:0]                     mux_axi_wvalid;
  logic [NUM_M:0]                     mux_axi_bready;

  // Concatenate with the null signal
  assign mux_axi_araddr  = {{AXI_ADDR_WIDTH{1'b0}}, in_axi_araddr};
  assign mux_axi_arvalid = {1'b0, in_axi_arvalid};
  assign mux_axi_rready  = {1'b0, in_axi_rready};
  assign mux_axi_awaddr  = {{AXI_ADDR_WIDTH{1'b0}}, in_axi_awaddr};
  assign mux_axi_awvalid = {1'b0, in_axi_awvalid};
  assign mux_axi_wdata   = {{AXI_DATA_WIDTH{1'b0}}, in_axi_wdata};
  assign mux_axi_wstrb   = {{AXI_STRB_WIDTH{1'b0}}, in_axi_wstrb};
  assign mux_axi_wvalid  = {1'b0, in_axi_wvalid};
  assign mux_axi_bready  = {1'b0, in_axi_bready};

  // Mux the signals
  assign out_axi_araddr  = mux_axi_araddr[rg_req];
  assign out_axi_arvalid = mux_axi_arvalid[rg_req];
  assign out_axi_awaddr  = mux_axi_awaddr[wg_req];
  assign out_axi_rready  = mux_axi_rready[wg_req];
  assign out_axi_awvalid = mux_axi_awvalid[wg_req];
  assign out_axi_wdata   = mux_axi_wdata[wg_req];
  assign out_axi_wstrb   = mux_axi_wstrb[wg_req];
  assign out_axi_wvalid  = mux_axi_wvalid[wg_req];
  assign out_axi_bready  = mux_axi_bready[wg_resp];

  //
  // Routing out->in
  //
  localparam M_BITS = $clog2(NUM_M);
  logic [M_BITS-1:0] mux_rg_req;
  logic [M_BITS-1:0] mux_rg_resp;
  logic [M_BITS-1:0] mux_wg_req;
  logic [M_BITS-1:0] mux_wg_resp;

  assign mux_rg_req  = rg_req[M_BITS-1:0];
  assign mux_rg_resp = rg_resp[M_BITS-1:0];
  assign mux_wg_req  = wg_req[M_BITS-1:0];
  assign mux_wg_resp = wg_resp[M_BITS-1:0];

  // read req
  always_comb begin
    in_axi_arready = '0;

    if (rg_req_active) begin
      in_axi_arready[mux_rg_req] = out_axi_arready;
    end
  end

  // read resp
  always_comb begin
    in_axi_rvalid = '0;
    in_axi_rdata  = '0;
    in_axi_rresp  = '0;

    if (rg_resp_active) begin
      in_axi_rvalid[mux_rg_resp] = out_axi_rvalid;
      in_axi_rdata[mux_rg_resp]  = out_axi_rdata;
      in_axi_rresp[mux_rg_resp]  = out_axi_rresp;
    end
  end

  // write req
  always_comb begin
    in_axi_awready = '0;
    in_axi_wready  = '0;

    if (wg_req_active) begin
      in_axi_awready[mux_wg_req] = out_axi_awready;
      in_axi_wready[mux_wg_req]  = out_axi_wready;
    end
  end

  // write resp
  always_comb begin
    in_axi_bvalid = '0;
    in_axi_bresp  = '0;

    if (wg_resp_active) begin
      in_axi_bvalid[mux_wg_resp] = out_axi_bvalid;
      in_axi_bresp[mux_wg_resp]  = out_axi_bresp;
    end
  end

endmodule

`endif
