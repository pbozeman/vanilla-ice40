`ifndef SKIDBUF_DEMO_V
`define SKIDBUF_DEMO_V

`include "directives.sv"

`include "axis_skidbuf.sv"
`include "skidbuf_demo_axis_dst.sv"
`include "skidbuf_demo_axis_mid.sv"
`include "skidbuf_demo_axis_src.sv"

module skidbuf_demo #(
    parameter DATA_BITS   = 8,
    parameter NUM_PRE_SB  = 16,
    parameter NUM_POST_SB = 16,
    parameter USE_SB      = 1
) (
    input clk,
    input reset,

    // fpga io pins
    input  logic [DATA_BITS-1:0] data_in,
    output logic [DATA_BITS-1:0] data_out
);
  logic                 pre_tvalid [NUM_PRE_SB-1:0];
  logic                 pre_tready [NUM_PRE_SB-1:0];
  logic [DATA_BITS-1:0] pre_tdata  [NUM_PRE_SB-1:0];

  logic                 post_tvalid[NUM_PRE_SB-1:0];
  logic                 post_tready[NUM_PRE_SB-1:0];
  logic [DATA_BITS-1:0] post_tdata [NUM_PRE_SB-1:0];

  skidbuf_demo_axis_src #(
      .DATA_BITS(DATA_BITS)
  ) src_i (
      .axi_clk   (clk),
      .axi_resetn(~reset),

      .m_axi_tvalid(pre_tvalid[0]),
      .m_axi_tready(pre_tready[0]),
      .m_axi_tdata (pre_tdata[0]),

      .data_in(data_in)
  );

  for (genvar i = 0; i < NUM_PRE_SB - 1; i++) begin : gen_pre
    skidbuf_demo_axis_mid #(
        .DATA_BITS(DATA_BITS)
    ) pre_mid_i (
        .axi_clk   (clk),
        .axi_resetn(~reset),

        .m_axi_tvalid(pre_tvalid[i+1]),
        .m_axi_tready(pre_tready[i+1]),
        .m_axi_tdata (pre_tdata[i+1]),

        .s_axi_tvalid(pre_tvalid[i]),
        .s_axi_tready(pre_tready[i]),
        .s_axi_tdata (pre_tdata[i])
    );
  end

  if (!USE_SB) begin : gen_non_sb
    skidbuf_demo_axis_mid #(
        .DATA_BITS(DATA_BITS)
    ) no_sb_i (
        .axi_clk   (clk),
        .axi_resetn(~reset),

        .m_axi_tvalid(post_tvalid[0]),
        .m_axi_tready(post_tready[0]),
        .m_axi_tdata (post_tdata[0]),

        .s_axi_tvalid(pre_tvalid[NUM_PRE_SB-1]),
        .s_axi_tready(pre_tready[NUM_PRE_SB-1]),
        .s_axi_tdata (pre_tdata[NUM_PRE_SB-1])
    );
  end else begin : gen_sb
    // The star of the show
    axis_skidbuf #(
        .DATA_BITS(DATA_BITS)
    ) skidbuf_i (
        .axi_clk   (clk),
        .axi_resetn(~reset),

        .m_axi_tvalid(post_tvalid[0]),
        .m_axi_tready(post_tready[0]),
        .m_axi_tdata (post_tdata[0]),

        .s_axi_tvalid(pre_tvalid[NUM_PRE_SB-1]),
        .s_axi_tready(pre_tready[NUM_PRE_SB-1]),
        .s_axi_tdata (pre_tdata[NUM_PRE_SB-1])
    );
  end

  for (genvar i = 0; i < NUM_POST_SB - 1; i++) begin : gen_post
    skidbuf_demo_axis_mid #(
        .DATA_BITS(DATA_BITS)
    ) sb_axis_mid_i (
        .axi_clk   (clk),
        .axi_resetn(~reset),

        .m_axi_tvalid(post_tvalid[i+1]),
        .m_axi_tready(post_tready[i+1]),
        .m_axi_tdata (post_tdata[i+1]),

        .s_axi_tvalid(post_tvalid[i]),
        .s_axi_tready(post_tready[i]),
        .s_axi_tdata (post_tdata[i])
    );
  end

  skidbuf_demo_axis_dst #(
      .DATA_BITS(DATA_BITS)
  ) dst_i (
      .axi_clk     (clk),
      .axi_resetn  (~reset),
      .s_axi_tvalid(post_tvalid[NUM_POST_SB-1]),
      .s_axi_tready(post_tready[NUM_POST_SB-1]),
      .s_axi_tdata (post_tdata[NUM_POST_SB-1]),
      .data_out    (data_out)
  );

endmodule
`endif
