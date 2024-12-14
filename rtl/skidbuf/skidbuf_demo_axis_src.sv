`ifndef SKIDBUF_DEMO_AXIS_SRC_V
`define SKIDBUF_DEMO_AXIS_SRC_V

`include "directives.sv"

module skidbuf_demo_axis_src #(
    parameter DATA_BITS = 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    output logic                 m_axi_tvalid,
    input  logic                 m_axi_tready,
    output logic [DATA_BITS-1:0] m_axi_tdata,

    input logic [DATA_BITS-1:0] data_in
);

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      m_axi_tvalid <= 1'b0;
    end else begin
      // we just keep streaming as long as the downstream is ready
      if (!m_axi_tvalid || m_axi_tready) begin
        m_axi_tvalid <= 1'b1;
        m_axi_tdata  <= data_in;
      end
    end
  end

endmodule
`endif
