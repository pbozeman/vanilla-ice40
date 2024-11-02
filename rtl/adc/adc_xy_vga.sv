`ifndef ADC_XY_VGA_V
`define ADC_XY_VGA_V

`include "directives.sv"

`include "adc_xy.sv"
`include "delay.sv"
`include "gfx_clear.sv"
`include "gfx_vga.sv"
`include "vga_mode.sv"

module adc_xy_vga #(
    parameter ADC_DATA_BITS  = 10,
    parameter VGA_WIDTH      = `VGA_MODE_H_VISIBLE,
    parameter VGA_HEIGHT     = `VGA_MODE_V_VISIBLE,
    parameter PIXEL_BITS     = 12,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,

    localparam FB_X_BITS  = $clog2(VGA_WIDTH),
    localparam FB_Y_BITS  = $clog2(VGA_HEIGHT),
    localparam COLOR_BITS = PIXEL_BITS / 3
) (
    input logic clk,
    input logic adc_clk,
    input logic pixel_clk,
    input logic reset,

    // adc signals
    input logic [ADC_DATA_BITS-1:0] adc_x_bus,
    input logic [ADC_DATA_BITS-1:0] adc_y_bus,

    // vga signals
    output logic [COLOR_BITS-1:0] vga_red,
    output logic [COLOR_BITS-1:0] vga_grn,
    output logic [COLOR_BITS-1:0] vga_blu,
    output logic                  vga_hsync,
    output logic                  vga_vsync,

    // sram0 controller to io pins
    output logic [AXI_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire  [AXI_DATA_WIDTH-1:0] sram_io_data,
    output logic                      sram_io_we_n,
    output logic                      sram_io_oe_n,
    output logic                      sram_io_ce_n
);
  // adc signals
  logic [ADC_DATA_BITS-1:0] adc_x;
  logic [ADC_DATA_BITS-1:0] adc_y;

  logic [ADC_DATA_BITS-1:0] gfx_adc_x;
  logic [ADC_DATA_BITS-1:0] gfx_adc_y;

  // clear screen signals
  logic [    FB_X_BITS-1:0] clr_x;
  logic [    FB_Y_BITS-1:0] clr_y;
  logic [   PIXEL_BITS-1:0] clr_color;
  logic                     clr_valid;
  logic                     clr_ready;
  logic                     clr_last;
  logic                     clr_inc;

  // gfx signals
  logic [    FB_X_BITS-1:0] gfx_x;
  logic [    FB_Y_BITS-1:0] gfx_y;
  logic [   PIXEL_BITS-1:0] gfx_color;
  logic                     gfx_valid;
  logic                     gfx_ready;

  logic                     vga_enable;

  //
  // clear screen before adc output
  //
  assign clr_inc = (clr_valid & gfx_ready);
  gfx_clear #(
      .FB_WIDTH  (VGA_WIDTH),
      .FB_HEIGHT (VGA_HEIGHT),
      .PIXEL_BITS(PIXEL_BITS)
  ) gfx_clear_inst (
      .clk  (clk),
      .reset(reset),
      .inc  (clr_inc),
      .x    (clr_x),
      .y    (clr_y),
      .color(clr_color),
      .valid(clr_valid),
      .last (clr_last)
  );

  //
  // adc
  //
  adc_xy #(
      .DATA_BITS(ADC_DATA_BITS)
  ) adc_xy_inst (
      .clk      (clk),
      .reset    (reset),
      .adc_clk  (adc_clk),
      .adc_x_bus(adc_x_bus),
      .adc_y_bus(adc_y_bus),
      .adc_x    (adc_x),
      .adc_y    (adc_y)
  );

  always @(posedge clk) begin
    // Temporary work around for the fact that our signal is 0 to 1024 while our
    // fb is 640x480. Just get something on the screen as a POC.
    gfx_adc_x <= adc_x >> 2;
    gfx_adc_y <= adc_y >> 2;
  end


  // output mux
  assign gfx_x     = clr_valid ? clr_x : gfx_adc_x;
  assign gfx_y     = clr_valid ? clr_y : gfx_adc_y;
  assign gfx_color = clr_valid ? clr_color : {PIXEL_BITS{1'b1}};
  assign gfx_valid = 1'b1;

  //
  // vga
  //
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
