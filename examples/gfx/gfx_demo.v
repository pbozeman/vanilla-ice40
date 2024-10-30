`ifndef GFX_DEMO_V
`define GFX_DEMO_V

`include "directives.v"

`include "delay.v"
`include "gfx_test_pattern.v"
`include "gfx_vga.v"

// verilator lint_off UNUSEDSIGNAL
module gfx_demo #(
    parameter VGA_WIDTH      = 640,
    parameter VGA_HEIGHT     = 480,
    parameter PIXEL_BITS     = 12,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input wire clk,
    input wire pixel_clk,
    input wire reset,

    // vga signals
    output wire [COLOR_BITS-1:0] vga_red,
    output wire [COLOR_BITS-1:0] vga_grn,
    output wire [COLOR_BITS-1:0] vga_blu,
    output wire                  vga_hsync,
    output wire                  vga_vsync,

    // sram0 controller to io pins
    output wire [AXI_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram_io_data,
    output wire                      sram_io_we_n,
    output wire                      sram_io_oe_n,
    output wire                      sram_io_ce_n
);
  localparam FB_X_BITS = $clog2(VGA_WIDTH);
  localparam FB_Y_BITS = $clog2(VGA_HEIGHT);
  localparam COLOR_BITS = PIXEL_BITS / 3;

  // gfx signals
  wire [ FB_X_BITS-1:0] gfx_x;
  wire [ FB_Y_BITS-1:0] gfx_y;
  wire [PIXEL_BITS-1:0] gfx_color;
  wire                  gfx_inc;
  wire                  gfx_last;
  wire                  gfx_valid;
  wire                  gfx_ready;

  reg                   vga_enable;

  gfx_test_pattern gfx_inst (
      .clk  (clk),
      .reset(reset),
      .inc  (gfx_inc),
      .x    (gfx_x),
      .y    (gfx_y),
      .color(gfx_color),
      .valid(gfx_valid),
      .last (gfx_last)
  );

  gfx_vga #(
      .VGA_WIDTH     (VGA_WIDTH),
      .VGA_HEIGHT    (VGA_HEIGHT),
      .PIXEL_BITS    (PIXEL_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) gfx_vga_inst (
      .clk      (clk),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .gfx_x    (gfx_x),
      .gfx_y    (gfx_y),
      .gfx_color(gfx_color),
      .gfx_valid(gfx_valid),
      .gfx_ready(gfx_ready),

      .vga_enable(vga_enable),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),

      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  assign gfx_inc = (gfx_valid & gfx_ready);

  // Give the gfx side some time to start laying down pixels before
  // we stream them to the display.
  delay #(
      .DELAY_CYCLES(8)
  ) vga_fb_delay (
      .clk(clk),
      .in (~reset),
      .out(vga_enable)
  );

endmodule

`endif
