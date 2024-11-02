`ifndef CDC_FIFO_WPTR_FULL_V
`define CDC_FIFO_WPTR_FULL_V

`include "directives.sv"

// This is for almost full. The Cummings paper (and this module)
// compares the gray codes directly to determine the full flag. However,
// I am not smart enough to figure out how to do a range based almost
// full check.. ie. I want it to be true when the w_ptr is N elements
// close to the r_ptr. < and > don't work on gray codes, so this
// module converts the read ptr to binary for the comparison.
//
`include "gray_to_bin.sv"

//
// From:
// http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
//
// 6.6 wptr_full.v - Write pointer & full generation logic
//

module cdc_fifo_wptr_full #(
    parameter ADDR_SIZE       = 4,
    parameter ALMOST_FULL_BUF = 1
) (
    input                 w_clk,
    input                 w_rst_n,
    input                 w_inc,
    input [ADDR_SIZE : 0] w_q2_rptr,

    output logic                 w_full,
    output logic                 w_almost_full,
    output logic [ADDR_SIZE : 0] w_ptr = 0,
    output logic [ADDR_SIZE-1:0] w_addr
);
  logic [ADDR_SIZE:0] w_bin = 0;
  logic [ADDR_SIZE:0] w_bin_next;
  logic [ADDR_SIZE:0] w_gray_next;

  // Memory write-address pointer (okay to use binary to address memory)
  assign w_addr      = w_bin[ADDR_SIZE-1:0];

  //
  // Pointers
  //
  // next pointer values
  //
  assign w_bin_next  = w_bin + (w_inc & ~w_full);
  assign w_gray_next = (w_bin_next >> 1) ^ w_bin_next;

  // register next pointer values
  always_ff @(posedge w_clk) begin
    if (!w_rst_n) begin
      w_bin <= 0;
      w_ptr <= 0;
    end else begin
      w_bin <= w_bin_next;
      w_ptr <= w_gray_next;
    end
  end

  //
  // Full
  //
  logic w_full_val;
  assign w_full_val = (w_gray_next == {~w_q2_rptr[ADDR_SIZE:ADDR_SIZE-1],
                                       w_q2_rptr[ADDR_SIZE-2:0]});

  //
  // Almost Full
  //

  logic [ADDR_SIZE:0] w_r_bin;
  gray_to_bin #(
      .WIDTH(ADDR_SIZE + 1)
  ) rg2b (
      .gray(w_q2_rptr),
      .bin (w_r_bin)
  );

  logic [ADDR_SIZE:0] w_slots_used;
  assign w_slots_used = w_bin - w_r_bin;


  localparam ALMOST_FULL_SLOTS = (1 << ADDR_SIZE) - ALMOST_FULL_BUF;
  logic w_almost_full_val;
  assign w_almost_full_val = w_slots_used >= ALMOST_FULL_SLOTS;

  // Register full flags
  always_ff @(posedge w_clk) begin
    if (!w_rst_n) begin
      w_full <= 1'b0;
    end else begin
      w_almost_full <= w_almost_full_val;
      w_full        <= w_full_val;
    end
  end

endmodule

`endif
