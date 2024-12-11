`ifndef VGA_PIXEL_ADDR_V
`define VGA_PIXEL_ADDR_V

`include "directives.sv"

`include "iter.sv"
`include "vga_mode.sv"

module vga_pixel_addr #(
    parameter H_WHOLE_LINE  = `VGA_MODE_H_WHOLE_LINE,
    parameter V_WHOLE_FRAME = `VGA_MODE_V_WHOLE_FRAME,

    localparam COLUMN_BITS = $clog2(H_WHOLE_LINE),
    localparam ROW_BITS    = $clog2(V_WHOLE_FRAME)
) (
    input  logic                   clk,
    input  logic                   reset,
    input  logic                   enable,
    output logic [COLUMN_BITS-1:0] column,
    output logic [   ROW_BITS-1:0] row
);
  logic col_last;
  logic row_last;

  // Using enable with the init might seem strange, but the reason is that we
  // init is similar to inc. The caller doesn't want values to change when
  // enable is low.
  iter #(
      .WIDTH(COLUMN_BITS)
  ) h_counter_i (
      .clk     (clk),
      .init    (reset || (col_last && enable)),
      .init_val('0),
      .max_val (COLUMN_BITS'(H_WHOLE_LINE - 1)),
      .inc     (enable),
      .val     (column),
      .last    (col_last)
  );

  iter #(
      .WIDTH(ROW_BITS)
  ) v_counter_i (
      .clk     (clk),
      .init    (reset || (row_last && col_last && enable)),
      .init_val('0),
      .max_val (ROW_BITS'(V_WHOLE_FRAME - 1)),
      .inc     (col_last && enable),
      .val     (row),
      .last    (row_last)
  );

endmodule

`endif
