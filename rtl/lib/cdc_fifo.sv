`ifndef CDC_FIFO_V
`define CDC_FIFO_V

`include "directives.sv"

`include "cdc_fifo_mem.sv"
`include "cdc_fifo_rptr_empty.sv"
`include "cdc_fifo_wptr_full.sv"
`include "cdc_sync2.sv"

//
// From:
// http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
//
// 6.1 fifo1.v - FIFO top-level module
//

module cdc_fifo #(
    parameter DATA_WIDTH      = 8,
    parameter ADDR_SIZE       = 4,
    parameter ALMOST_FULL_BUF = 1
) (
    // Write clock domain inputs
    input logic                  w_clk,
    input logic                  w_rst_n,
    input logic                  w_inc,
    input logic [DATA_WIDTH-1:0] w_data,

    // Write clock domain output
    output logic w_almost_full,
    output logic w_full,

    // Read clock domain inputs
    input logic r_clk,
    input logic r_rst_n,
    input logic r_inc,

    // Read clock domain outputs
    output logic                  r_empty,
    output logic [DATA_WIDTH-1:0] r_data
);
  logic [ADDR_SIZE-1:0] w_addr;
  logic [ADDR_SIZE-1:0] r_addr;

  logic [  ADDR_SIZE:0] w_ptr;
  logic [  ADDR_SIZE:0] r_ptr;
  logic [  ADDR_SIZE:0] w_q2_rptr;
  logic [  ADDR_SIZE:0] r_q2_wptr;

  cdc_sync2 #(ADDR_SIZE + 1) sync_r2w (
      .clk  (w_clk),
      .rst_n(w_rst_n),
      .d    (r_ptr),
      .q    (w_q2_rptr)
  );

  cdc_sync2 #(ADDR_SIZE + 1) sync_w2r (
      .clk  (r_clk),
      .rst_n(r_rst_n),
      .d    (w_ptr),
      .q    (r_q2_wptr)
  );

  cdc_fifo_mem #(DATA_WIDTH, ADDR_SIZE) fifo_mem (
      .w_clk   (w_clk),
      .w_clk_en(w_inc),
      .w_full  (w_full),
      .w_addr  (w_addr),
      .w_data  (w_data),
      .r_addr  (r_addr),
      .r_data  (r_data)
  );

  cdc_fifo_rptr_empty #(ADDR_SIZE) rptr_empty (
      .r_clk    (r_clk),
      .r_rst_n  (r_rst_n),
      .r_inc    (r_inc),
      .r_q2_wptr(r_q2_wptr),
      .r_empty  (r_empty),
      .r_ptr    (r_ptr),
      .r_addr   (r_addr)
  );

  cdc_fifo_wptr_full #(
      .ADDR_SIZE      (ADDR_SIZE),
      .ALMOST_FULL_BUF(ALMOST_FULL_BUF)
  ) wptr_full (
      .w_clk        (w_clk),
      .w_rst_n      (w_rst_n),
      .w_inc        (w_inc),
      .w_q2_rptr    (w_q2_rptr),
      .w_almost_full(w_almost_full),
      .w_full       (w_full),
      .w_ptr        (w_ptr),
      .w_addr       (w_addr)
  );
endmodule

`endif
