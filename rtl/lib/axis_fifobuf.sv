`ifndef AXIS_FIFOBUF_V
`define AXIS_FIFOBUF_V

`include "directives.sv"

`include "sync_fifo.sv"

//
// N deep buffer from s to m
//
module axis_fifobuf #(
    parameter DATA_WIDTH           = 8,
    parameter FIFO_ADDR_SIZE       = 4,
    parameter FIFO_ALMOST_FULL_BUF = 4
) (
    input logic axi_clk,
    input logic axi_resetn,

    input  logic                  s_axi_tvalid,
    output logic                  s_axi_tready,
    input  logic [DATA_WIDTH-1:0] s_axi_tdata,

    output logic                  m_axi_tvalid,
    input  logic                  m_axi_tready,
    output logic [DATA_WIDTH-1:0] m_axi_tdata
);
  logic                  fifo_w_inc;
  logic                  fifo_w_almost_full;
  logic [DATA_WIDTH-1:0] fifo_w_data;

  logic                  fifo_r_inc;
  logic                  fifo_r_empty;
  logic [DATA_WIDTH-1:0] fifo_r_data;

  sync_fifo #(
      .DATA_WIDTH     (DATA_WIDTH),
      .ADDR_SIZE      (FIFO_ADDR_SIZE),
      .ALMOST_FULL_BUF(FIFO_ALMOST_FULL_BUF)
  ) fifo_i (
      .clk          (axi_clk),
      .rst_n        (axi_resetn),
      .w_inc        (fifo_w_inc),
      .w_almost_full(fifo_w_almost_full),
      .w_full       (),
      .w_data       (fifo_w_data),
      .r_inc        (fifo_r_inc),
      .r_empty      (fifo_r_empty),
      .r_data       (fifo_r_data)
  );

  assign fifo_w_inc   = s_axi_tready && s_axi_tvalid;
  assign fifo_w_data  = s_axi_tdata;
  assign s_axi_tready = !fifo_w_almost_full;

  assign m_axi_tvalid = !fifo_r_empty;
  assign m_axi_tdata  = fifo_r_data;
  assign fifo_r_inc   = m_axi_tvalid && m_axi_tready;

endmodule
`endif
