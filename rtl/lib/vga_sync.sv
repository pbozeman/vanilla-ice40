`ifndef VGA_SYNC_V
`define VGA_SYNC_V

`include "directives.sv"

`include "vga_mode.sv"
`include "vga_pixel_iter.sv"

module vga_sync #(
    parameter H_VISIBLE     = 640,
    parameter H_FRONT_PORCH = 16,
    parameter H_SYNC_PULSE  = 96,
    // verilator lint_off UNUSEDPARAM
    parameter H_BACK_PORCH  = 48,
    // verilator lint_on UNUSEDPARAM
    parameter H_WHOLE_LINE  = 800,

    parameter V_VISIBLE     = 640,
    parameter V_FRONT_PORCH = 10,
    parameter V_SYNC_PULSE  = 2,
    // verilator lint_off UNUSEDPARAM
    parameter V_BACK_PORCH  = 33,
    // verilator lint_on UNUSEDPARAM
    parameter V_WHOLE_FRAME = 525,

    localparam X_BITS = $clog2(H_WHOLE_LINE),
    localparam Y_BITS = $clog2(V_WHOLE_FRAME)
) (
    input  logic              clk,
    input  logic              reset,
    input  logic              inc,
    output logic              visible,
    output logic              hsync,
    output logic              vsync,
    output logic [X_BITS-1:0] x,
    output logic [Y_BITS-1:0] y
);
  localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
  localparam H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;

  localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
  localparam V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;

  vga_pixel_iter #(H_WHOLE_LINE, V_WHOLE_FRAME) addr (
      .clk   (clk),
      .reset (reset),
      .inc   (inc),
      .x     (x),
      .y     (y),
      .x_last(),
      .y_last()
  );

  assign visible = (x < H_VISIBLE && y < V_VISIBLE) ? 1 : 0;
  assign hsync   = (x >= H_SYNC_START && x < H_SYNC_END) ? 0 : 1;
  assign vsync   = (y >= V_SYNC_START && y < V_SYNC_END) ? 0 : 1;

endmodule

`endif
