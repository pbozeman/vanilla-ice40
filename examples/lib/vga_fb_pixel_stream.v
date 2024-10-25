`ifndef VGA_FB_PIXEL_STREAM_V
`define VGA_FB_PIXEL_STREAM_V

// This runs in the axi clock domain and is expected to be bridged
// via a fifo to a module pushing bits to the vga.

`include "directives.v"

// `include "counter.v"
`include "vga_sync.v"

module vga_fb_pixel_stream #(
    parameter PIXEL_BITS = 12,

    parameter H_VISIBLE     = 640,
    parameter H_FRONT_PORCH = 16,
    parameter H_SYNC_PULSE  = 96,
    parameter H_BACK_PORCH  = 48,
    parameter H_WHOLE_LINE  = 800,

    parameter V_VISIBLE     = 480,
    parameter V_FRONT_PORCH = 10,
    parameter V_SYNC_PULSE  = 2,
    parameter V_BACK_PORCH  = 33,
    parameter V_WHOLE_FRAME = 525,

    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input wire clk,
    input wire reset,
    input wire enable,

    // sync signals
    output wire vsync,
    output wire hsync,

    // color
    output wire [COLOR_BITS-1:0] red,
    output wire [COLOR_BITS-1:0] grn,
    output wire [COLOR_BITS-1:0] blu,

    output wire valid,

    output wire [AXI_ADDR_WIDTH-1:0] xxx_addr,

    //
    // The AXI interface backing the frame buffer.
    // This module is the master.
    //
    output reg  [AXI_ADDR_WIDTH-1:0] sram_axi_araddr,
    output reg                       sram_axi_arvalid,
    input  wire                      sram_axi_arready,
    input  wire [AXI_DATA_WIDTH-1:0] sram_axi_rdata,
    output reg                       sram_axi_rready,
    // verilator lint_off UNUSEDSIGNAL
    input  wire [               1:0] sram_axi_rresp,
    input  wire                      sram_axi_rvalid
    // verilator lint_on UNUSEDSIGNAL
);
  localparam MAX_PIXEL_ADDR = H_VISIBLE * V_VISIBLE - 1;
  localparam COLOR_BITS = PIXEL_BITS / 3;

  wire fb_pixel_visible;
  wire fb_pixel_hsync;
  wire fb_pixel_vsync;
  wire [AXI_ADDR_WIDTH-1:0] fb_pixel_addr;

  // verilator lint_off UNUSEDSIGNAL
  wire [9:0] fb_pixel_column;
  wire [9:0] fb_pixel_row;
  // verilator lint_on UNUSEDSIGNAL

  // In this context, fb_pixel_visible is the previous value. Keep generating
  // pixels in the non-visible area as long as we are enabled. Otherwise,
  // we need to wait for our reads to get registered before we clobber them.
  wire fb_pixel_inc = (read_start | (!fb_pixel_visible & enable));

  vga_sync #(
      .H_VISIBLE    (H_VISIBLE),
      .H_FRONT_PORCH(H_FRONT_PORCH),
      .H_SYNC_PULSE (H_SYNC_PULSE),
      .H_BACK_PORCH (H_BACK_PORCH),
      .H_WHOLE_LINE (H_WHOLE_LINE),
      .V_VISIBLE    (V_VISIBLE),
      .V_FRONT_PORCH(V_FRONT_PORCH),
      .V_SYNC_PULSE (V_SYNC_PULSE),
      .V_BACK_PORCH (V_BACK_PORCH),
      .V_WHOLE_FRAME(V_WHOLE_FRAME)
  ) sync (
      .clk    (clk),
      .reset  (reset),
      .enable (fb_pixel_inc),
      .visible(fb_pixel_visible),
      .hsync  (fb_pixel_hsync),
      .vsync  (fb_pixel_vsync),
      .column (fb_pixel_column),
      .row    (fb_pixel_row)
  );

  // This was measured to be faster than a counter. When registering the
  // final outputs just before sending them (to pipeline the addr calc),
  // multiply was achieving 145Mhz maxf while the counter was 112 maxf.
  assign fb_pixel_addr = (H_VISIBLE * fb_pixel_row + fb_pixel_column);

  wire read_start;
  assign read_start = 1'b1;

  always @(*) begin
    sram_axi_araddr = fb_pixel_addr;
  end

  reg                      final_vsync;
  reg                      final_hsync;
  reg [AXI_ADDR_WIDTH-1:0] final_xxx_addr;

  always @(posedge clk) begin
    final_vsync    <= fb_pixel_vsync;
    final_hsync    <= fb_pixel_hsync;
    final_xxx_addr <= fb_pixel_addr;
  end

  assign hsync    = final_hsync;
  assign vsync    = final_vsync;
  assign xxx_addr = final_xxx_addr;

endmodule

`endif
