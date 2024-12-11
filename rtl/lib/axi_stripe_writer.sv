`ifndef AXI_STRIPE_WRITER_V
`define AXI_STRIPE_WRITER_V

`include "directives.sv"

`include "axi_stripe_router.sv"
`include "sticky_bit.sv"

// Unlike the reader, this module does not take an length, it's
// just a single word, but, is a thin-ish wrapper for doing the
// routing
module axi_stripe_writer #(
    parameter  NUM_S          = 2,
    parameter  AXI_ADDR_WIDTH = 20,
    parameter  AXI_DATA_WIDTH = 16,
    localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    input  logic [AXI_ADDR_WIDTH-1:0] in_axi_awaddr,
    input  logic                      in_axi_awvalid,
    output logic                      in_axi_awready,
    input  logic [AXI_DATA_WIDTH-1:0] in_axi_wdata,
    input  logic [AXI_STRB_WIDTH-1:0] in_axi_wstrb,
    input  logic                      in_axi_wvalid,
    output logic                      in_axi_wready,
    output logic [               1:0] in_axi_bresp,
    output logic                      in_axi_bvalid,
    input  logic                      in_axi_bready,

    // Subordinate interfaces
    output logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] out_axi_awaddr,
    output logic [NUM_S-1:0]                     out_axi_awvalid,
    input  logic [NUM_S-1:0]                     out_axi_awready,
    output logic [NUM_S-1:0][AXI_DATA_WIDTH-1:0] out_axi_wdata,
    output logic [NUM_S-1:0][AXI_STRB_WIDTH-1:0] out_axi_wstrb,
    output logic [NUM_S-1:0]                     out_axi_wvalid,
    input  logic [NUM_S-1:0]                     out_axi_wready,
    input  logic [NUM_S-1:0][               1:0] out_axi_bresp,
    input  logic [NUM_S-1:0]                     out_axi_bvalid,
    output logic [NUM_S-1:0]                     out_axi_bready
);
  localparam SEL_BITS = $clog2(NUM_S);
  localparam R_BITS = $clog2(NUM_S + 1);
  localparam CHANNEL_IDLE = {R_BITS{1'b1}};

  // The full versions of these are basically just +1 bit
  // where the extra bit is an active bit. This was to be consistent with the
  // other maxing interfaces, back from a time when these were used to select
  // into an actual array. Now that that method isn't used anymore, we should
  // likely have some sort of explicit req/resp active or valid bit instead.
  // Although for now, just be consistent with the rest of the design.
  logic [  R_BITS-1:0] req_full;
  logic [  R_BITS-1:0] resp_full;

  logic [SEL_BITS-1:0] req;
  logic [SEL_BITS-1:0] resp;

  logic                awdone;
  logic                wdone;
  logic                req_accepted;
  logic                resp_accepted;

  logic                req_idle;
  logic                resp_idle;

  assign req_accepted  = awdone && wdone;
  assign resp_accepted = in_axi_bvalid && in_axi_bready;

  assign req_idle      = req_full == CHANNEL_IDLE;
  assign resp_idle     = resp_full == CHANNEL_IDLE;

  assign req           = req_full[SEL_BITS-1:0];
  assign resp          = resp_full[SEL_BITS-1:0];

  sticky_bit sticky_awdone (
      .clk  (axi_clk),
      .reset(~axi_resetn),
      .in   (in_axi_awvalid && in_axi_awready),
      .out  (awdone),
      .clear(req_accepted)
  );

  sticky_bit sticky_wdone (
      .clk  (axi_clk),
      .reset(~axi_resetn),
      .in   (in_axi_wvalid && in_axi_wready),
      .out  (wdone),
      .clear(req_accepted)
  );

  axi_stripe_router #(
      .SEL_BITS(SEL_BITS)
  ) axi_stripe_router_i (
      .axi_clk      (axi_clk),
      .axi_resetn   (axi_resetn),
      .axi_avalid   (in_axi_awvalid),
      .axi_addr     (in_axi_awaddr),
      .req_accepted (req_accepted),
      .resp_accepted(resp_accepted),
      .req          (req_full),
      .resp         (resp_full)
  );

  //
  // Muxing
  //
  always_comb begin
    out_axi_awaddr  = '0;
    out_axi_awvalid = '0;

    out_axi_wdata   = '0;
    out_axi_wstrb   = '0;
    out_axi_wvalid  = '0;

    out_axi_bready  = '0;

    if (!req_idle) begin
      // AW channel
      out_axi_awaddr[req]  = in_axi_awaddr;
      out_axi_awvalid[req] = in_axi_awvalid;

      // W channel
      out_axi_wdata[req]   = in_axi_wdata;
      out_axi_wstrb[req]   = in_axi_wstrb;
      out_axi_wvalid[req]  = in_axi_wvalid;
    end

    if (!resp_idle) begin
      // B channel
      out_axi_bready[resp] = in_axi_bready;
    end
  end

  always_comb begin
    in_axi_awready = '0;
    in_axi_wready  = '0;

    in_axi_bresp   = '0;
    in_axi_bvalid  = '0;

    if (!req_idle) begin
      // AW and W
      in_axi_awready = out_axi_awready[req];
      in_axi_wready  = out_axi_wready[req];
    end

    if (!resp_idle) begin
      in_axi_bresp  = out_axi_bresp[resp];
      in_axi_bvalid = out_axi_bvalid[resp];
    end
  end

endmodule

`endif
