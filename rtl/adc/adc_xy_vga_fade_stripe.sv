`ifndef ADC_XY_VGA_FADE_STRIPE_V
`define ADC_XY_VGA_FADE_STRIPE_V

`include "directives.sv"

`include "axis_skidbuf.sv"
`include "adc_xy_axi.sv"
`include "delay.sv"
`include "gfx_clear.sv"
`include "gfx_vga_fade_stripe.sv"
`include "vga_mode.sv"

module adc_xy_vga_fade_stripe #(
    parameter NUM_S         = 2,
    parameter ADC_DATA_BITS = 10,

    parameter PIXEL_BITS = 12,

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
    input logic [ADC_DATA_BITS-1:0] adc_x_io,
    input logic [ADC_DATA_BITS-1:0] adc_y_io,
    input logic                     adc_red_io,
    input logic                     adc_grn_io,
    input logic                     adc_blu_io,

    // vga signals
    output logic [COLOR_BITS-1:0] vga_red,
    output logic [COLOR_BITS-1:0] vga_grn,
    output logic [COLOR_BITS-1:0] vga_blu,
    output logic                  vga_hsync,
    output logic                  vga_vsync,

    // sram controller to io pins
    output logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire  [NUM_S-1:0][AXI_DATA_WIDTH-1:0] sram_io_data,
    output logic [NUM_S-1:0]                     sram_io_we_n,
    output logic [NUM_S-1:0]                     sram_io_oe_n,
    output logic [NUM_S-1:0]                     sram_io_ce_n

);
  // adc signals
  logic [ADC_DATA_BITS-1:0] adc_x;
  logic [ADC_DATA_BITS-1:0] adc_y;
  logic                     adc_red;
  logic                     adc_grn;
  logic                     adc_blu;

  logic [ADC_DATA_BITS-1:0] gfx_adc_x;
  // verilator lint_off UNUSEDSIGNAL
  // See the FIXME below
  logic [ADC_DATA_BITS-1:0] gfx_adc_y;
  // verilator lint_on UNUSEDSIGNAL
  logic [   COLOR_BITS-1:0] gfx_adc_red;
  logic [   COLOR_BITS-1:0] gfx_adc_grn;
  logic [   COLOR_BITS-1:0] gfx_adc_blu;
  logic [   PIXEL_BITS-1:0] gfx_adc_color;

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
  logic                     gfx_pvalid;
  logic                     gfx_pready;

  logic [    FB_X_BITS-1:0] vga_gfx_x;
  logic [    FB_Y_BITS-1:0] vga_gfx_y;
  logic [   PIXEL_BITS-1:0] vga_gfx_color;
  logic                     vga_gfx_pvalid;
  logic                     vga_gfx_pready;

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
      .clk       (clk),
      .reset     (reset),
      .adc_clk   (adc_clk),
      .enable    (adc_active),
      .tvalid    (adc_tvalid),
      .tready    (adc_tready),
      .adc_x_io  (adc_x_io),
      .adc_y_io  (adc_y_io),
      .adc_red_io(adc_red_io),
      .adc_grn_io(adc_grn_io),
      .adc_blu_io(adc_blu_io),
      .adc_x     (adc_x),
      .adc_y     (adc_y),
      .adc_red   (adc_red),
      .adc_grn   (adc_grn),
      .adc_blu   (adc_blu)
  );
  assign gfx_adc_x     = adc_x;
  assign gfx_adc_y     = adc_y;

  assign gfx_adc_red   = {COLOR_BITS{adc_red}};
  assign gfx_adc_grn   = {COLOR_BITS{adc_grn}};
  assign gfx_adc_blu   = {COLOR_BITS{adc_blu}};
  assign gfx_adc_color = {gfx_adc_red, gfx_adc_grn, gfx_adc_blu};

  // output mux
  // FIXME: make adc_y match FB_Y in the port list
  assign gfx_x         = adc_active ? gfx_adc_x : clr_x;
  assign gfx_y         = adc_active ? gfx_adc_y[FB_Y_BITS-1:0] : clr_y;
  assign gfx_color     = adc_active ? gfx_adc_color : clr_color;

  assign gfx_pvalid    = adc_active ? adc_tvalid : clr_pvalid;
  assign clr_pready    = gfx_pready;

  axis_skidbuf #(
      .DATA_BITS(FB_X_BITS + FB_Y_BITS + PIXEL_BITS)
  ) gfx_sb (
      .axi_clk   (clk),
      .axi_resetn(~reset),

      .s_axi_tvalid(gfx_pvalid),
      .s_axi_tready(gfx_pready),
      .s_axi_tdata ({gfx_x, gfx_y, gfx_color}),

      .m_axi_tvalid(vga_gfx_pvalid),
      .m_axi_tready(vga_gfx_pready),
      .m_axi_tdata ({vga_gfx_x, vga_gfx_y, vga_gfx_color})
  );

  //
  // vga
  //
  gfx_vga_fade_stripe #(
      .NUM_S(NUM_S),

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

      .PIXEL_BITS(PIXEL_BITS)
  ) gfx_vga_fade_inst (
      .clk      (clk),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .gfx_valid(vga_gfx_pvalid),
      .gfx_ready(vga_gfx_pready),
      .gfx_x    (vga_gfx_x),
      .gfx_y    (vga_gfx_y),
      .gfx_color(vga_gfx_color),

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

  // Clear screen before we start
  logic clr_last_delay;

  delay #(
      .DELAY_CYCLES(8)
  ) adc_active_delay (
      .clk(clk),
      .in (clr_last),
      .out(clr_last_delay)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      adc_active <= 1'b0;
      vga_enable <= 1'b0;
    end else begin
      if (!vga_enable) begin
        vga_enable <= clr_last_delay;
      end

      if (!adc_active) begin
        adc_active <= clr_last_delay;
      end
    end
  end

endmodule
`endif
