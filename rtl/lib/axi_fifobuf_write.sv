`ifndef AXI_FIFOBUF_WRITE_V
`define AXI_FIFOBUF_WRITE_V

`include "directives.sv"

`include "axis_fifobuf.sv"

module axi_fifobuf_write #(
    parameter  integer AXI_ADDR_WIDTH = 20,
    parameter  integer AXI_DATA_WIDTH = 16,
    localparam         AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8
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
    input  logic                      s_axi_bready,

    output logic [AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output logic                      m_axi_awvalid,
    input  logic                      m_axi_awready,
    output logic [AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output logic [AXI_STRB_WIDTH-1:0] m_axi_wstrb,
    output logic                      m_axi_wvalid,
    input  logic                      m_axi_wready,
    input  logic [               1:0] m_axi_bresp,
    input  logic                      m_axi_bvalid,
    output logic                      m_axi_bready
);

  axis_fifobuf #(
      .DATA_WIDTH(AXI_ADDR_WIDTH)
  ) aw_fb (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .s_axi_tvalid(s_axi_awvalid),
      .s_axi_tready(s_axi_awready),
      .s_axi_tdata (s_axi_awaddr),
      .m_axi_tvalid(m_axi_awvalid),
      .m_axi_tready(m_axi_awready),
      .m_axi_tdata (m_axi_awaddr)
  );

  axis_fifobuf #(
      .DATA_WIDTH(AXI_DATA_WIDTH + AXI_STRB_WIDTH)
  ) w_fb (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .s_axi_tvalid(s_axi_wvalid),
      .s_axi_tready(s_axi_wready),
      .s_axi_tdata ({s_axi_wdata, s_axi_wstrb}),
      .m_axi_tvalid(m_axi_wvalid),
      .m_axi_tready(m_axi_wready),
      .m_axi_tdata ({m_axi_wdata, m_axi_wstrb})
  );

  axis_fifobuf #(
      .DATA_WIDTH(2)
  ) b_fb (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .s_axi_tvalid(m_axi_bvalid),
      .s_axi_tready(m_axi_bready),
      .s_axi_tdata (m_axi_bresp),
      .m_axi_tvalid(s_axi_bvalid),
      .m_axi_tready(s_axi_bready),
      .m_axi_tdata (s_axi_bresp)
  );

endmodule

`endif
