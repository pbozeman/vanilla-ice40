// defaults to industry standard 640x480@60Hz
// http://www.tinyvga.com/vga-timing/640x480@60Hz
module vga #(
    parameter H_VISIBLE = 640,
    parameter H_FRONT_PORCH = 16,
    parameter H_SYNC_PULSE = 96,
    parameter H_BACK_PORCH = 48,
    parameter H_WHOLE_LINE = 800,

    parameter V_VISIBLE = 480,
    parameter V_FRONT_PORCH = 10,
    parameter V_SYNC_PULSE = 2,
    parameter V_BACK_PORCH = 33,
    parameter V_WHOLE_FRAME = 525
) (
    input clk_i,
    input reset_i,
    output visible_o,
    output hsync_o,
    output vsync_o,
    output [9:0] column_o,
    output [9:0] row_o
);

  localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
  localparam H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;

  localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
  localparam V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;

  pixel_addr #(H_WHOLE_LINE, V_WHOLE_FRAME) addr (
      clk_i,
      reset_i,
      column_o,
      row_o
  );

  assign visible_o = (column_o < H_VISIBLE && row_o < V_VISIBLE) ? 1 : 0;
  assign hsync_o   = (column_o >= H_SYNC_START && column_o < H_SYNC_END) ? 0 : 1;
  assign vsync_o   = (row_o >= V_SYNC_START && row_o < V_SYNC_END) ? 0 : 1;

endmodule
