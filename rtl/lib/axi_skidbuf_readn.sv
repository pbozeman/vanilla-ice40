`ifndef AXI_SKIDBUF_READN_V
`define AXI_SKIDBUF_READN_V

`include "directives.sv"

`include "axis_skidbuf.sv"

module axi_skidbuf_readn #(
    parameter integer AXI_ADDR_WIDTH   = 20,
    parameter integer AXI_DATA_WIDTH   = 16,
    parameter         AXI_ARLENW_WIDTH = 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    input  logic [  AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  logic [AXI_ARLENW_WIDTH-1:0] s_axi_arlenw,
    input  logic                        s_axi_arvalid,
    output logic                        s_axi_arready,
    output logic [  AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output logic                        s_axi_rlast,
    output logic [                 1:0] s_axi_rresp,
    output logic                        s_axi_rvalid,
    input  logic                        s_axi_rready,

    output logic [  AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    output logic [AXI_ARLENW_WIDTH-1:0] m_axi_arlenw,
    output logic                        m_axi_arvalid,
    input  logic                        m_axi_arready,
    input  logic [  AXI_DATA_WIDTH-1:0] m_axi_rdata,
    input  logic                        m_axi_rlast,
    input  logic [                 1:0] m_axi_rresp,
    input  logic                        m_axi_rvalid,
    output logic                        m_axi_rready
);

  axis_skidbuf #(
      .DATA_BITS(AXI_ADDR_WIDTH + AXI_ARLENW_WIDTH)
  ) ar_sb (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .s_axi_tvalid(s_axi_arvalid),
      .s_axi_tready(s_axi_arready),
      .s_axi_tdata ({s_axi_araddr, s_axi_arlenw}),
      .m_axi_tvalid(m_axi_arvalid),
      .m_axi_tready(m_axi_arready),
      .m_axi_tdata ({m_axi_araddr, m_axi_arlenw})
  );

  axis_skidbuf #(
      .DATA_BITS(AXI_DATA_WIDTH + 3)
  ) r_sb (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .s_axi_tvalid(m_axi_rvalid),
      .s_axi_tready(m_axi_rready),
      .s_axi_tdata ({m_axi_rresp, m_axi_rlast, m_axi_rdata}),
      .m_axi_tvalid(s_axi_rvalid),
      .m_axi_tready(s_axi_rready),
      .m_axi_tdata ({s_axi_rresp, s_axi_rlast, s_axi_rdata})
  );

endmodule

`endif
