`ifndef GFX_DEMO_3TO2_V
`define GFX_DEMO_3TO2_V

`include "directives.sv"

`include "delay.sv"
`include "gfx_test_pattern.sv"
`include "gfx_vga_3to2.sv"
`include "vga_mode.sv"

// verilator lint_off UNUSEDSIGNAL
module gfx_demo_3to2 #(
    parameter VGA_WIDTH      = `VGA_MODE_H_VISIBLE,
    parameter VGA_HEIGHT     = `VGA_MODE_V_VISIBLE,
    parameter PIXEL_BITS     = 12,
    parameter META_BITS      = 4,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input logic clk,
    input logic pixel_clk,
    input logic reset,

    // vga signals
    output logic [COLOR_BITS-1:0] vga_red,
    output logic [COLOR_BITS-1:0] vga_grn,
    output logic [COLOR_BITS-1:0] vga_blu,
    output logic [ META_BITS-1:0] vga_meta,
    output logic                  vga_hsync,
    output logic                  vga_vsync,

    // sram1 controller to io pins
    output logic [AXI_ADDR_WIDTH-1:0] sram0_io_addr,
    inout  wire  [AXI_DATA_WIDTH-1:0] sram0_io_data,
    output logic                      sram0_io_we_n,
    output logic                      sram0_io_oe_n,
    output logic                      sram0_io_ce_n,

    // sram1 controller to io pins
    output logic [AXI_ADDR_WIDTH-1:0] sram1_io_addr,
    inout  wire  [AXI_DATA_WIDTH-1:0] sram1_io_data,
    output logic                      sram1_io_we_n,
    output logic                      sram1_io_oe_n,
    output logic                      sram1_io_ce_n
);
  localparam FB_X_BITS = $clog2(VGA_WIDTH);
  localparam FB_Y_BITS = $clog2(VGA_HEIGHT);
  localparam COLOR_BITS = PIXEL_BITS / 3;

  // gfx signals
  logic [ FB_X_BITS-1:0] gfx_x;
  logic [ FB_Y_BITS-1:0] gfx_y;
  logic [PIXEL_BITS-1:0] gfx_color;
  logic [ META_BITS-1:0] gfx_meta;
  logic                  gfx_pready;
  logic                  gfx_pvalid;
  logic                  gfx_last;
  logic                  gfx_ready;
  logic                  gfx_vsync;

  logic                  vga_enable;

  gfx_test_pattern gfx_inst (
      .clk   (clk),
      .reset (reset),
      .pready(gfx_pready),
      .pvalid(gfx_pvalid),
      .x     (gfx_x),
      .y     (gfx_y),
      .color (gfx_color),
      .last  (gfx_last)
  );

  // TODO: use this
  assign gfx_meta = '0;

  gfx_vga_3to2 #(
      .VGA_WIDTH     (VGA_WIDTH),
      .VGA_HEIGHT    (VGA_HEIGHT),
      .PIXEL_BITS    (PIXEL_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) gfx_vga_3to2_inst (
      .clk      (clk),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .gfx_x    (gfx_x),
      .gfx_y    (gfx_y),
      .gfx_color(gfx_color),
      .gfx_meta (gfx_meta),
      .gfx_valid(gfx_pvalid),
      .gfx_ready(gfx_pready),
      .gfx_vsync(gfx_vsync),

      .vga_enable(vga_enable),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_meta (vga_meta),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),

      .sram0_io_addr(sram0_io_addr),
      .sram0_io_data(sram0_io_data),
      .sram0_io_we_n(sram0_io_we_n),
      .sram0_io_oe_n(sram0_io_oe_n),
      .sram0_io_ce_n(sram0_io_ce_n),

      .sram1_io_addr(sram1_io_addr),
      .sram1_io_data(sram1_io_data),
      .sram1_io_we_n(sram1_io_we_n),
      .sram1_io_oe_n(sram1_io_oe_n),
      .sram1_io_ce_n(sram1_io_ce_n)
  );

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