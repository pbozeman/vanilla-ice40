`ifndef VGA_SYNC_V
`define VGA_SYNC_V

`include "directives.v"

`include "vga_pixel_addr.v"

// defaults to industry standard 640x480@60Hz
// http://www.tinyvga.com/vga-timing/640x480@60Hz
module vga_sync #(
    parameter H_VISIBLE     = 640,
    parameter H_FRONT_PORCH = 16,
    parameter H_SYNC_PULSE  = 96,
    // verilator lint_off UNUSEDPARAM
    parameter H_BACK_PORCH  = 48,
    // verilator lint_on UNUSEDPARAM
    parameter H_WHOLE_LINE  = 800,

    parameter V_VISIBLE     = 480,
    parameter V_FRONT_PORCH = 10,
    parameter V_SYNC_PULSE  = 2,
    // verilator lint_off UNUSEDPARAM
    parameter V_BACK_PORCH  = 33,
    // verilator lint_on UNUSEDPARAM
    parameter V_WHOLE_FRAME = 525
) (
    input  wire       clk,
    input  wire       reset,
    output wire       visible,
    output wire       hsync,
    output wire       vsync,
    output wire [9:0] column,
    output wire [9:0] row
);

  localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
  localparam H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;

  localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
  localparam V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;

  vga_pixel_addr #(H_WHOLE_LINE, V_WHOLE_FRAME) addr (
      .clk   (clk),
      .reset (reset),
      .column(column),
      .row   (row)
  );

  assign visible = (column < H_VISIBLE && row < V_VISIBLE) ? 1 : 0;
  assign hsync   = (column >= H_SYNC_START && column < H_SYNC_END) ? 0 : 1;
  assign vsync   = (row >= V_SYNC_START && row < V_SYNC_END) ? 0 : 1;

endmodule

`endif
