`ifndef AXIS_SKIDBUF_V
`define AXIS_SKIDBUF_V

`include "directives.sv"

// This follows the formally verified sb implementation from
// https://zipcpu.com/blog/2019/05/22/skidbuffer.html
//
// This module strips out some of the extra options and
// complexity of the zipcpu implementation, reducing it
// to the core functionality.

module axis_skidbuf #(
    parameter DATA_BITS = 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    input  logic                 s_axi_tvalid,
    output logic                 s_axi_tready,
    input  logic [DATA_BITS-1:0] s_axi_tdata,

    output logic                 m_axi_tvalid,
    input  logic                 m_axi_tready,
    output logic [DATA_BITS-1:0] m_axi_tdata
);
  reg                 skid_s_tvalid;
  reg [DATA_BITS-1:0] skid_s_tdata;

  //
  // s side
  //
  always @(posedge axi_clk) begin
    if (~axi_resetn) begin
      skid_s_tvalid <= 1'b0;
    end else begin
      if ((s_axi_tvalid && s_axi_tready) &&
          (m_axi_tvalid && !m_axi_tready)) begin
        // we have incoming data, but the outgoing data is stalled
        skid_s_tvalid <= 1'b1;
      end else if (m_axi_tready) begin
        skid_s_tvalid <= 1'b0;
      end
    end
  end

  always @(posedge axi_clk) begin
    if (~axi_resetn) begin
      skid_s_tdata <= 0;
    end else begin
      if (!s_axi_tvalid || m_axi_tready) begin
        skid_s_tdata <= 0;
      end else if (s_axi_tvalid && s_axi_tready) begin
        skid_s_tdata <= s_axi_tdata;
      end
    end
  end

  assign s_axi_tready = !skid_s_tvalid;

  //
  // m side
  //
  reg skid_m_tvalid;

  always @(posedge axi_clk) begin
    if (~axi_resetn) begin
      skid_m_tvalid <= 1'b0;
    end else begin
      if (!m_axi_tvalid || m_axi_tready) begin
        skid_m_tvalid <= s_axi_tvalid || skid_s_tvalid;
      end
    end
  end

  assign m_axi_tvalid = skid_m_tvalid;

  always @(posedge axi_clk) begin
    if (~axi_resetn) begin
      m_axi_tdata <= 0;
    end else begin
      if (!m_axi_tvalid || m_axi_tready) begin
        if (skid_s_tvalid) begin
          m_axi_tdata <= skid_s_tdata;
        end else if (s_axi_tvalid) begin
          m_axi_tdata <= s_axi_tdata;
        end else begin
          m_axi_tdata <= 0;
        end
      end
    end
  end

endmodule

`endif
