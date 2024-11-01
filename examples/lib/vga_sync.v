`ifndef VGA_SYNC_V
`define VGA_SYNC_V

`include "directives.v"

`include "vga_mode.v"
`include "vga_pixel_addr.v"

module vga_sync #(
    parameter H_VISIBLE     = `VGA_MODE_H_VISIBLE,
    parameter H_FRONT_PORCH = `VGA_MODE_H_FRONT_PORCH,
    parameter H_SYNC_PULSE  = `VGA_MODE_H_SYNC_PULSE,
    // verilator lint_off UNUSEDPARAM
    parameter H_BACK_PORCH  = `VGA_MODE_H_BACK_PORCH,
    // verilator lint_on UNUSEDPARAM
    parameter H_WHOLE_LINE  = `VGA_MODE_H_WHOLE_LINE,

    parameter V_VISIBLE     = `VGA_MODE_V_VISIBLE,
    parameter V_FRONT_PORCH = `VGA_MODE_V_FRONT_PORCH,
    parameter V_SYNC_PULSE  = `VGA_MODE_V_SYNC_PULSE,
    // verilator lint_off UNUSEDPARAM
    parameter V_BACK_PORCH  = `VGA_MODE_V_BACK_PORCH,
    // verilator lint_on UNUSEDPARAM
    parameter V_WHOLE_FRAME = `VGA_MODE_V_WHOLE_FRAME
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   enable,
    output wire                   visible,
    output wire                   hsync,
    output wire                   vsync,
    output wire [COLUMN_BITS-1:0] column,
    output wire [   ROW_BITS-1:0] row
);
  localparam COLUMN_BITS = $clog2(H_WHOLE_LINE);
  localparam ROW_BITS = $clog2(V_WHOLE_FRAME);

  localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
  localparam H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;

  localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
  localparam V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;

  vga_pixel_addr #(H_WHOLE_LINE, V_WHOLE_FRAME) addr (
      .clk   (clk),
      .reset (reset),
      .enable(enable),
      .column(column),
      .row   (row)
  );

  assign visible = (column < H_VISIBLE && row < V_VISIBLE) ? 1 : 0;
  assign hsync   = (column >= H_SYNC_START && column < H_SYNC_END) ? 0 : 1;
  assign vsync   = (row >= V_SYNC_START && row < V_SYNC_END) ? 0 : 1;

endmodule

`endif
