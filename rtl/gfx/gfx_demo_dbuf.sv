`ifndef GFX_DEMO_DBUF_V
`define GFX_DEMO_DBUF_V


`include "directives.sv"

`include "delay.sv"
`include "detect_rising.sv"
`include "detect_falling.sv"
`include "gfx_test_pattern.sv"
`include "gfx_vga_dbuf.sv"
`include "vga_mode.sv"

// verilator lint_off UNUSEDSIGNAL
module gfx_demo_dbuf #(
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
  localparam FB_X_BITS = $clog2(VGA_WIDTH);
  localparam FB_Y_BITS = $clog2(VGA_HEIGHT);
  localparam COLOR_BITS = PIXEL_BITS / 3;

  // gfx signals
  logic [ FB_X_BITS-1:0] gfx_x;
  logic [ FB_Y_BITS-1:0] gfx_y;
  logic [PIXEL_BITS-1:0] gfx_color;
  logic [ META_BITS-1:0] gfx_meta;
  logic                  gfx_inc;
  logic                  gfx_last;
  logic                  gfx_valid;
  logic                  gfx_ready;
  logic                  gfx_vsync;

  logic                  vga_enable;

  logic                  mem_switch;

  gfx_test_pattern gfx_inst (
      .clk  (clk),
      .reset(reset | mem_switch),
      .inc  (gfx_inc),
      .x    (gfx_x),
      .y    (gfx_y),
      .color(gfx_color),
      .valid(gfx_valid),
      .last (gfx_last)
  );

  // TODO: use this
  assign gfx_meta = '0;

  // fb writer axi flow control signals
  logic fbw_axi_tvalid;
  logic fbw_axi_tready;

  gfx_vga_dbuf #(
      .VGA_WIDTH     (VGA_WIDTH),
      .VGA_HEIGHT    (VGA_HEIGHT),
      .PIXEL_BITS    (PIXEL_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) gfx_vga_inst (
      .clk      (clk),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .mem_switch(mem_switch),

      .gfx_x    (gfx_x),
      .gfx_y    (gfx_y),
      .gfx_color(gfx_color),
      .gfx_meta (gfx_meta),
      .gfx_valid(gfx_valid),
      .gfx_ready(gfx_ready),
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

  assign gfx_inc = (gfx_valid & gfx_ready);

  // We can't enable the vga output until we are told the gfx engine has
  // initialized the first buffer. Otherwise, we will be reading unitilized
  // data. While this is probably fine for a real display, this leads to an
  // assertion in test benches. Delay a bit to make sure all writes have fully
  // flushed. (Which is a bit of a hack, but let's just make it work for now)
  //
  // We also need to switch memory buffers. See below.
  logic gfx_last_d;
  delay #(
      .DELAY_CYCLES(8)
  ) vga_fb_delay (
      .clk(clk),
      .in (gfx_last),
      .out(gfx_last_d)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      vga_enable <= 0;
    end else begin
      if (!vga_enable) begin
        vga_enable <= gfx_last_d;
      end
    end
  end

  //
  // FB double buffer switching logic
  //
  logic negedge_vsync;
  detect_falling falling_sram_vga_vsync (
      .clk     (clk),
      .signal  (gfx_vsync),
      .detected(negedge_vsync)
  );

  // we normally switch on vsync, but we also want to switch after the first
  // frame is written and we are ready to enable the vga.
  logic posedge_vga_enable;
  detect_rising rising_pattern_done (
      .clk     (clk),
      .signal  (vga_enable),
      .detected(posedge_vga_enable)
  );

  assign mem_switch = posedge_vga_enable | negedge_vsync;

endmodule
// verilator lint_on UNUSEDSIGNAL

`endif
