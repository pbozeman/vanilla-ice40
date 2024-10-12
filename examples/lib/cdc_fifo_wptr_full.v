`ifndef CDC_FIFO_WPTR_FULL_V
`define CDC_FIFO_WPTR_FULL_V

`include "directives.v"

//
// From:
// http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
//
// 6.6 wptr_full.v - Write pointer & full generation logic
//

module cdc_fifo_wptr_full #(
    parameter ADDR_SIZE = 4
) (
    input                 w_clk,
    input                 w_rst_n,
    input                 w_inc,
    input [ADDR_SIZE : 0] w_q2_rptr,

    output reg                  w_full,
    output reg                  w_almost_full,
    output reg  [ADDR_SIZE : 0] w_ptr = 0,
    output wire [ADDR_SIZE-1:0] w_addr
);
  reg  [ADDR_SIZE:0] w_bin = 0;
  wire [ADDR_SIZE:0] w_bin_next;
  wire [ADDR_SIZE:0] w_gray_next;
  wire [ADDR_SIZE:0] w_gray_next_next;

  // Memory write-address pointer (okay to use binary to address memory)
  assign w_addr           = w_bin[ADDR_SIZE-1:0];

  //
  // Pointers
  //
  // next pointer values
  // Note: there is probably a better way of doing the grey_next_next
  // that is used for almost full, but this was quick and easy
  // to understand conceptually.
  //
  assign w_bin_next       = w_bin + (w_inc & ~w_full);
  assign w_gray_next      = (w_bin_next >> 1) ^ w_bin_next;
  assign w_gray_next_next = ((w_bin_next + 1) >> 1) ^ (w_bin_next + 1);

  // register next pointer values
  always @(posedge w_clk or negedge w_rst_n) begin
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
  wire w_full_val;
  wire w_almost_full_val;

  assign w_full_val = (w_gray_next == {~w_q2_rptr[ADDR_SIZE:ADDR_SIZE-1],
                                       w_q2_rptr[ADDR_SIZE-2:0]});

  assign w_almost_full_val = (
      w_gray_next_next ==
          {~w_q2_rptr[ADDR_SIZE:ADDR_SIZE-1], w_q2_rptr[ADDR_SIZE-2:0]});

  always @(posedge w_clk or negedge w_rst_n) begin
    if (!w_rst_n) begin
      w_full <= 1'b0;
    end else begin
      w_almost_full <= w_almost_full_val;
      w_full        <= w_full_val;
    end
  end

endmodule

`endif
