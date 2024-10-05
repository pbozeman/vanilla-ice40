`ifndef CDC_FIFO_RPTR_EMPTY_V
`define CDC_FIFO_RPTR_EMPTY_V

`include "directives.v"

//
// From:
// http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
//
// 6.5 rptr_empty.v - Read pointer & empty generation logic
//

module cdc_fifo_rptr_empty #(
    parameter ADDR_SIZE = 4
) (
    input r_clk,
    input r_rst_n,
    input r_inc,
    input [ADDR_SIZE : 0] r_q2_wptr,

    output reg r_empty,
    output reg [ADDR_SIZE : 0] r_ptr = 0,
    output wire [ADDR_SIZE-1:0] r_addr
);
  reg  [ADDR_SIZE:0] r_bin = 0;
  wire [ADDR_SIZE:0] r_gray_next;
  wire [ADDR_SIZE:0] r_bin_next;

  // Memory read-address pointer (okay to use binary to address memory)
  assign r_addr = r_bin[ADDR_SIZE-1:0];

  //
  // Pointers
  //
  // next pointer values
  assign r_bin_next = r_bin + (r_inc & ~r_empty);
  assign r_gray_next = (r_bin_next >> 1) ^ r_bin_next;

  // register next pointer values
  always @(posedge r_clk or negedge r_rst_n) begin
    if (!r_rst_n) begin
      r_bin <= 0;
      r_ptr <= 0;
    end else begin
      r_bin <= r_bin_next;
      r_ptr <= r_gray_next;
    end
  end

  //
  // Empty
  //
  // FIFO empty when the next r_ptr == synchronized w_ptr or on reset
  //
  wire r_empty_val;
  assign r_empty_val = (r_gray_next == r_q2_wptr);

  always @(posedge r_clk or negedge r_rst_n) begin
    if (!r_rst_n) begin
      r_empty <= 1'b1;
    end else begin
      r_empty <= r_empty_val;
    end
  end
endmodule

`endif
