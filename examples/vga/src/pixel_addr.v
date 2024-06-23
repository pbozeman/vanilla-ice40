// defaults to 640x480
// http://www.tinyvga.com/vga-timing/640x480@60Hz

// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module pixel_addr #(
    parameter H_WHOLE_LINE  = 800,
    parameter V_WHOLE_FRAME = 525
) (
    input clk_i,
    input reset_i,
    output [9:0] column_o,
    output [9:0] row_o
);

  localparam ENABLE = 1'b1;

  counter #(H_WHOLE_LINE - 1) h_counter (
      clk_i,
      reset_i,
      ENABLE,
      column_o
  );

  counter #(V_WHOLE_FRAME - 1) v_counter (
      clk_i,
      reset_i,
      column_o == H_WHOLE_LINE - 1,
      row_o
  );

endmodule
