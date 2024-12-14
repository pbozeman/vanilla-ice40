`ifndef SKIDBUF_DEMO_AXIS_MID_V
`define SKIDBUF_DEMO_AXIS_MID_V

`include "directives.sv"

`include "counter.sv"

module skidbuf_demo_axis_mid #(
    parameter DATA_BITS = 8
) (
    // verilator lint_off UNUSEDSIGNAL
    input logic axi_clk,
    input logic axi_resetn,
    // verilator lint_on UNUSEDSIGNAL

    output logic                 m_axi_tvalid,
    input  logic                 m_axi_tready,
    output logic [DATA_BITS-1:0] m_axi_tdata,

    input  logic                 s_axi_tvalid,
    output logic                 s_axi_tready,
    input  logic [DATA_BITS-1:0] s_axi_tdata
);

  logic [DATA_BITS-1:0] val;

  // This was the easiest way to ensure some other combinatorial logic was
  // happening at each stage.
  counter #(
      .WIDTH(DATA_BITS)
  ) counter_i (
      .clk   (axi_clk),
      .reset (~axi_resetn),
      .enable(1'b1),
      .val   (val)
  );

  assign m_axi_tvalid = s_axi_tvalid;
  assign m_axi_tdata  = s_axi_tdata + val;
  assign s_axi_tready = m_axi_tready;

endmodule
`endif
