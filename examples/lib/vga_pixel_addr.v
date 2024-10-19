`ifndef VGA_PIXEL_ADDR_V
`define VGA_PIXEL_ADDR_V

`include "directives.v"

`include "counter.v"

// defaults to 640x480
// http://www.tinyvga.com/vga-timing/640x480@60Hz
module vga_pixel_addr #(
    parameter H_WHOLE_LINE  = 800,
    parameter V_WHOLE_FRAME = 525
) (
    input  wire       clk,
    input  wire       reset,
    output wire [9:0] column,
    output wire [9:0] row
);

  localparam enable = 1'b1;

  counter #(H_WHOLE_LINE - 1) h_counter (
      .clk   (clk),
      .reset (reset),
      .enable(enable),
      .count (column)
  );

  counter #(V_WHOLE_FRAME - 1) v_counter (
      .clk   (clk),
      .reset (reset),
      .enable(column == H_WHOLE_LINE - 1),
      .count (row)
  );

endmodule

`endif
