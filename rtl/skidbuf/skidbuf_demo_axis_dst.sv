`ifndef SKIDBUF_DEMO_AXIS_DST_V
`define SKIDBUF_DEMO_AXIS_DST_V

`include "directives.sv"

module skidbuf_demo_axis_dst #(
    parameter DATA_BITS = 8
) (
    input logic axi_clk,
    // verilator lint_off UNUSEDSIGNAL
    input logic axi_resetn,
    // verilator lint_on UNUSEDSIGNAL

    input  logic                 s_axi_tvalid,
    output logic                 s_axi_tready,
    input  logic [DATA_BITS-1:0] s_axi_tdata,

    output logic [DATA_BITS-1:0] data_out
);
  assign s_axi_tready = 1'b1;

  always_ff @(posedge axi_clk) begin
    if (s_axi_tvalid && s_axi_tready) begin
      data_out <= s_axi_tdata;
    end
  end

endmodule
`endif
