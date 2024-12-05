`ifndef VGA_PIXEL_ADDR_V
`define VGA_PIXEL_ADDR_V

`include "directives.sv"

`include "counter_fixed.sv"
`include "vga_mode.sv"

module vga_pixel_addr #(
    parameter H_WHOLE_LINE  = 800,
    parameter V_WHOLE_FRAME = 525,

    localparam COLUMN_BITS = $clog2(H_WHOLE_LINE),
    localparam ROW_BITS    = $clog2(V_WHOLE_FRAME)
) (
    input  logic                   clk,
    input  logic                   reset,
    input  logic                   enable,
    output logic [COLUMN_BITS-1:0] column,
    output logic [   ROW_BITS-1:0] row
);
  counter_fixed #(H_WHOLE_LINE - 1) h_counter_fixed (
      .clk   (clk),
      .reset (reset),
      .enable(enable),
      .count (column)
  );

  counter_fixed #(V_WHOLE_FRAME - 1) v_counter_fixed (
      .clk   (clk),
      .reset (reset),
      .enable(enable & (column == H_WHOLE_LINE - 1)),
      .count (row)
  );

endmodule

`endif
