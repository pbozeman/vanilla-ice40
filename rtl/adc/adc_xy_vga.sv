`ifndef ADC_XY_VGA_V
`define ADC_XY_VGA_V

`include "directives.sv"

`include "adc_xy_axi.sv"
`include "delay.sv"
// `include "detect_falling.sv"
`include "gfx_clear.sv"
`include "gfx_vga_3to2.sv"
`include "vga_mode.sv"

module adc_xy_vga #(
    parameter ADC_DATA_BITS = 10,

    parameter PIXEL_BITS = 12,
    parameter META_BITS  = 4,

    parameter H_VISIBLE     = `VGA_MODE_H_VISIBLE,
    parameter H_FRONT_PORCH = `VGA_MODE_H_FRONT_PORCH,
    parameter H_SYNC_PULSE  = `VGA_MODE_H_SYNC_PULSE,
    parameter H_BACK_PORCH  = `VGA_MODE_H_BACK_PORCH,
    parameter H_WHOLE_LINE  = `VGA_MODE_H_WHOLE_LINE,

    parameter V_VISIBLE     = `VGA_MODE_V_VISIBLE,
    parameter V_FRONT_PORCH = `VGA_MODE_V_FRONT_PORCH,
    parameter V_SYNC_PULSE  = `VGA_MODE_V_SYNC_PULSE,
    parameter V_BACK_PORCH  = `VGA_MODE_V_BACK_PORCH,
    parameter V_WHOLE_FRAME = `VGA_MODE_V_WHOLE_FRAME,

    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,

    localparam FB_X_BITS  = $clog2(H_VISIBLE),
    localparam FB_Y_BITS  = $clog2(V_VISIBLE),
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
    output logic [ META_BITS-1:0] vga_meta,
    output logic                  vga_hsync,
    output logic                  vga_vsync,

    // sram0 controller to io pins
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
  // localparam P_FRAME_BITS = $clog2(P_FRAMES);

  // adc signals
  logic [ADC_DATA_BITS-1:0] adc_x;
  logic [ADC_DATA_BITS-1:0] adc_y;

  logic [ADC_DATA_BITS-1:0] gfx_adc_x;
  logic [ADC_DATA_BITS-1:0] gfx_adc_y;

  // clear screen signals
  logic                     clr_pvalid;
  logic                     clr_pready;
  logic [    FB_X_BITS-1:0] clr_x;
  logic [    FB_Y_BITS-1:0] clr_y;
  logic [   PIXEL_BITS-1:0] clr_color;
  // verilator lint_off UNUSEDSIGNAL
  logic                     clr_last;
  // verilator lint_on UNUSEDSIGNAL

  // gfx signals
  logic [    FB_X_BITS-1:0] gfx_x;
  logic [    FB_Y_BITS-1:0] gfx_y;
  logic [   PIXEL_BITS-1:0] gfx_color;
  logic [    META_BITS-1:0] gfx_meta;
  logic                     gfx_pvalid;
  logic                     gfx_pready;
  // verilator lint_off UNUSEDSIGNAL
  logic                     gfx_vsync;
  // verilator lint_on UNUSEDSIGNAL

  logic                     vga_enable;
  logic                     adc_active;

  //
  // clear screen before adc output
  //
  gfx_clear #(
      .FB_WIDTH  (H_VISIBLE),
      .FB_HEIGHT (V_VISIBLE),
      .PIXEL_BITS(PIXEL_BITS)
  ) gfx_clear_inst (
      .clk   (clk),
      .reset (reset),
      .pready(clr_pready),
      .pvalid(clr_pvalid),
      .x     (clr_x),
      .y     (clr_y),
      .color (clr_color),
      .last  (clr_last)
  );

  //
  // adc
  //
  logic adc_tvalid;
  logic adc_tready;

  assign adc_tready = gfx_pready;

  adc_xy_axi #(
      .DATA_BITS(ADC_DATA_BITS)
  ) adc_xy_inst (
      .clk      (clk),
      .reset    (reset),
      .adc_clk  (adc_clk),
      .tvalid   (adc_tvalid),
      .tready   (adc_tready),
      .adc_x_bus(adc_x_bus),
      .adc_y_bus(adc_y_bus),
      .adc_x    (adc_x),
      .adc_y    (adc_y)
  );

  // Temporary work around for the fact that our signal is 0 to 1024 while our
  // fb is 640x480. Just get something on the screen as a POC.
  assign gfx_adc_x  = adc_x >> 1;
  assign gfx_adc_y  = adc_y >> 1;

  // Persistence
  // logic                    gfx_new_frame;
  // logic [P_FRAME_BITS-1:0] gfx_frame;

  // detect_falling gfx_vsync_falling_inst (
  //     .clk     (clk),
  //     .signal  (gfx_vsync),
  //     .detected(gfx_new_frame)
  // );
  //
  // always_ff @(posedge clk) begin
  //   if (reset) begin
  //     gfx_frame <= 0;
  //   end else begin
  //     if (gfx_new_frame) begin
  //       if (gfx_frame < P_FRAMES) begin
  //         gfx_frame <= gfx_frame + 1;
  //       end else begin
  //         gfx_frame <= 0;
  //       end
  //     end
  //   end
  // end

  // output mux
  assign gfx_x      = adc_active ? gfx_adc_x : clr_x;
  assign gfx_y      = adc_active ? gfx_adc_y : clr_y;
  assign gfx_color  = adc_active ? {PIXEL_BITS{1'b1}} : clr_color;
  assign gfx_meta   = '0;

  assign gfx_pvalid = adc_active ? adc_tvalid : clr_pvalid;
  assign clr_pready = gfx_pready;

  logic [COLOR_BITS-1:0] vga_raw_red;
  logic [COLOR_BITS-1:0] vga_raw_grn;
  logic [COLOR_BITS-1:0] vga_raw_blu;

  //
  // vga
  //
  gfx_vga_3to2 #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),

      .H_VISIBLE    (H_VISIBLE),
      .H_FRONT_PORCH(H_FRONT_PORCH),
      .H_SYNC_PULSE (H_SYNC_PULSE),
      .H_BACK_PORCH (H_BACK_PORCH),
      .H_WHOLE_LINE (H_WHOLE_LINE),

      .V_VISIBLE    (V_VISIBLE),
      .V_FRONT_PORCH(V_FRONT_PORCH),
      .V_SYNC_PULSE (V_SYNC_PULSE),
      .V_BACK_PORCH (V_BACK_PORCH),
      .V_WHOLE_FRAME(V_WHOLE_FRAME),

      .PIXEL_BITS(PIXEL_BITS),
      .META_BITS (META_BITS)
  ) gfx_vga_inst (
      .clk      (clk),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .gfx_valid(gfx_pvalid),
      .gfx_ready(gfx_pready),
      .gfx_x    (gfx_x),
      .gfx_y    (gfx_y),
      .gfx_color(gfx_color),
      .gfx_meta (gfx_meta),
      .gfx_vsync(gfx_vsync),

      .vga_enable(vga_enable),

      .vga_red  (vga_raw_red),
      .vga_grn  (vga_raw_grn),
      .vga_blu  (vga_raw_blu),
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

  // vga side frame/persistence tracking
  // logic                    vga_new_frame;
  // logic [P_FRAME_BITS-1:0] vga_frame;
  //
  // detect_falling vga_vsync_falling_inst (
  //     .clk     (pixel_clk),
  //     .signal  (vga_vsync),
  //     .detected(vga_new_frame)
  // );
  //
  // always_ff @(posedge pixel_clk) begin
  //   if (reset) begin
  //     vga_frame <= 0;
  //   end else begin
  //     if (vga_new_frame) begin
  //       if (vga_frame < P_FRAMES) begin
  //         vga_frame <= vga_frame + 1;
  //       end else begin
  //         vga_frame <= 0;
  //       end
  //     end
  //   end
  // end

  assign vga_red = vga_raw_red;
  assign vga_grn = vga_raw_grn;
  assign vga_blu = vga_raw_blu;

  // Give the gfx side some time to start laying down pixels before
  // we stream them to the display.
  delay #(
      .DELAY_CYCLES(8)
  ) vga_fb_delay (
      .clk(clk),
      .in (~reset),
      .out(vga_enable)
  );

  // wait for the clr to finish writing before we flip to the adc
  delay #(
      .DELAY_CYCLES(8)
  ) adc_active_delay (
      .clk(clk),
      .in (clr_last),
      .out(adc_active)
  );

endmodule
`endif
