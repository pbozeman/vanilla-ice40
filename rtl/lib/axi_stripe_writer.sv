`ifndef AXI_STRIPE_WRITER_V
`define AXI_STRIPE_WRITER_V

`include "directives.sv"

`include "axi_fifobuf_write.sv"

// This is not axi lite compliant in that the write response from the
// subordinates is ignored and not passed back to the manager. It's not really
// possible to do what this module is doing in an axi lite compliant way. It
// would need to be moved to full axi so that responses could be returned
// out of order... because the whole point of this module is to let a caller
// do linear writes at the combined bandwidth of the subordinates, which means,
// accepting new writes before old ones finish. And because there might be
// contention at a subordinate, there is no guarantee about which will finish
// first. Without an xid, we can't really return results.
//
// TODO: move to full axi for the reasons noted above.
module axi_stripe_writer #(
    parameter  NUM_S          = 2,
    parameter  AXI_ADDR_WIDTH = 20,
    parameter  AXI_DATA_WIDTH = 16,
    localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    input  logic [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  logic                      s_axi_awvalid,
    output logic                      s_axi_awready,
    input  logic [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  logic [AXI_STRB_WIDTH-1:0] s_axi_wstrb,
    input  logic                      s_axi_wvalid,
    output logic                      s_axi_wready,
    output logic [               1:0] s_axi_bresp,
    output logic                      s_axi_bvalid,
    // verilator lint_off UNUSEDSIGNAL
    input  logic                      s_axi_bready,
    // verilator lint_on UNUSEDSIGNAL

    // Subordinate interfaces
    output logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output logic [NUM_S-1:0]                     m_axi_awvalid,
    input  logic [NUM_S-1:0]                     m_axi_awready,
    output logic [NUM_S-1:0][AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output logic [NUM_S-1:0][AXI_STRB_WIDTH-1:0] m_axi_wstrb,
    output logic [NUM_S-1:0]                     m_axi_wvalid,
    input  logic [NUM_S-1:0]                     m_axi_wready,
    input  logic [NUM_S-1:0][               1:0] m_axi_bresp,
    input  logic [NUM_S-1:0]                     m_axi_bvalid,
    output logic [NUM_S-1:0]                     m_axi_bready
);
  localparam SEL_BITS = $clog2(NUM_S);

  logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] buf_axi_awaddr;
  logic [NUM_S-1:0]                     buf_axi_awvalid;
  logic [NUM_S-1:0]                     buf_axi_awready;
  logic [NUM_S-1:0][AXI_DATA_WIDTH-1:0] buf_axi_wdata;
  logic [NUM_S-1:0][AXI_STRB_WIDTH-1:0] buf_axi_wstrb;
  logic [NUM_S-1:0]                     buf_axi_wvalid;
  logic [NUM_S-1:0]                     buf_axi_wready;
  // verilator lint_off UNUSEDSIGNAL
  logic [NUM_S-1:0][               1:0] buf_axi_bresp;
  logic [NUM_S-1:0]                     buf_axi_bvalid;
  // verilator lint_on UNUSEDSIGNAL
  logic [NUM_S-1:0]                     buf_axi_bready;

  logic                                 fully_ready;

  // We could possibly be picky, but the logic would be more complicated, and
  // this is likely fine for our use cases.
  assign fully_ready   = &buf_axi_awready && &buf_axi_wready;
  assign s_axi_awready = fully_ready;
  assign s_axi_wready  = fully_ready;
  assign s_axi_bresp   = 2'b0;
  assign s_axi_bvalid  = 1'b1;

  for (genvar i = 0; i < NUM_S; i++) begin : gen_fifobuf
    axi_fifobuf_write #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) sync_fifo_i (
        .axi_clk   (axi_clk),
        .axi_resetn(axi_resetn),

        .s_axi_awaddr (buf_axi_awaddr[i]),
        .s_axi_awvalid(buf_axi_awvalid[i]),
        .s_axi_awready(buf_axi_awready[i]),
        .s_axi_wdata  (buf_axi_wdata[i]),
        .s_axi_wstrb  (buf_axi_wstrb[i]),
        .s_axi_wvalid (buf_axi_wvalid[i]),
        .s_axi_wready (buf_axi_wready[i]),
        .s_axi_bresp  (buf_axi_bresp[i]),
        .s_axi_bvalid (buf_axi_bvalid[i]),
        .s_axi_bready (buf_axi_bready[i]),

        .m_axi_awaddr (m_axi_awaddr[i]),
        .m_axi_awvalid(m_axi_awvalid[i]),
        .m_axi_awready(m_axi_awready[i]),
        .m_axi_wdata  (m_axi_wdata[i]),
        .m_axi_wstrb  (m_axi_wstrb[i]),
        .m_axi_wvalid (m_axi_wvalid[i]),
        .m_axi_wready (m_axi_wready[i]),
        .m_axi_bresp  (m_axi_bresp[i]),
        .m_axi_bvalid (m_axi_bvalid[i]),
        .m_axi_bready (m_axi_bready[i])
    );
  end

  logic [SEL_BITS-1:0] addr_sel;
  assign addr_sel = s_axi_awaddr[SEL_BITS-1:0];

  always_comb begin
    buf_axi_awaddr  = '0;
    buf_axi_awvalid = '0;
    buf_axi_wdata   = '0;
    buf_axi_wstrb   = '0;
    buf_axi_wvalid  = '0;
    buf_axi_bready  = '1;

    // Only route when we have both address and data valid, otherwise, we
    // would have to be buffering the writes to match to the right
    // destination. This might technically be a protocol violation, but will
    // work with our current managers.
    if (s_axi_awvalid && s_axi_wvalid) begin
      for (int i = 0; i < NUM_S; i++) begin
        if (addr_sel == SEL_BITS'(i)) begin
          buf_axi_awaddr[i]  = s_axi_awaddr;
          buf_axi_awvalid[i] = 1'b1;
          buf_axi_wdata[i]   = s_axi_wdata;
          buf_axi_wstrb[i]   = s_axi_wstrb;
          buf_axi_wvalid[i]  = 1'b1;
        end
      end
    end
  end

endmodule
`endif
