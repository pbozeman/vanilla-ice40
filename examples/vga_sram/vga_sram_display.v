`ifndef VGA_SRAM_DISPLAY_V
`define VGA_SRAM_DISPLAY_V

`include "directives.v"

`include "vga_pixel_addr.v"

// defaults to industry standard 640x480@60Hz
// http://www.tinyvga.com/vga-timing/640x480@60Hz
module vga_sram_display #(
    parameter ADDR_BITS = 20,
    parameter DATA_BITS = 16,

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
    input wire clk,
    input wire reset,

    input wire pattern_done,

    input  wire [DATA_BITS-1:0] sram_data,
    output wire [ADDR_BITS-1:0] sram_addr,

    output wire vsync,
    output wire hsync,
    output wire [3:0] red,
    output wire [3:0] green,
    output wire [3:0] blue
);
  localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
  localparam H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;

  localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
  localparam V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;

  wire [9:0] next_column;
  wire [9:0] next_row;

  wire visible;
  reg [9:0] column;
  reg [9:0] row;

  vga_pixel_addr #(H_WHOLE_LINE, V_WHOLE_FRAME) addr (
      clk,
      reset,
      next_column,
      next_row
  );

  // column and row (lagging sram addr, but current with data)
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      column <= 0;
      row <= 0;
    end else begin
      column <= next_column;
      row <= next_row;
    end
  end

  assign sram_addr = (next_row * H_VISIBLE) + next_column;

  // colors
  assign red = visible ? sram_data[15:12] : 4'b0000;
  assign green = visible ? sram_data[11:8] : 4'b0000;
  assign blue = visible ? sram_data[7:4] : 4'b0000;

  assign visible = (column < H_VISIBLE && row < V_VISIBLE) ? 1 : 0;
  assign hsync   = (column >= H_SYNC_START && column < H_SYNC_END) ? 0 : 1;
  assign vsync   = (row >= V_SYNC_START && row < V_SYNC_END) ? 0 : 1;

endmodule

`endif
