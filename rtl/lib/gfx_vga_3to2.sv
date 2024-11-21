`ifndef GFX_VGA_3TO2_V
`define GFX_VGA_3TO2_V

// FB GFX display with blanking that happens behind the pixel stream.
//
// This uses the axi_3x2, where 1 input to the 3x2 is drawing new pixels, one
// is reading and producing a pixel stream for the vga output, and another is
// blanking (and maybe dimming) the old pixels.
//
// TODO: blanking is not done yet.
//
// TODO: There is a lot of copy/paste going on between this, gfx_vga, and
// gfx_vga_dbuf. See the comment there about a potential refactor.

`include "directives.sv"

`include "axi_sram_3to2.sv"
`include "axi_sram_controller.sv"
`include "cdc_fifo.sv"
`include "fb_writer.sv"
`include "vga_mode.sv"
`include "vga_fb_pixel_stream.sv"

// meta bits are extra metadata that can be associated with the pixel. It
// might have been better to just the pixel be gfx_pixel_data rather than
// splitting color out and later. If that was (or later, is) done, then
// the vga_rgb lines should be separated out by the caller and we should
// only be passing gfx_pixel_data through this module. But, the interface is
// in flux, so let's just do the simple thing first when adding in the
// meta_bits, for now. (The initial use case is using them for intensity
// in simulating fade of a vector display.)
module gfx_vga_3to2 #(
    parameter PIXEL_BITS,
    parameter META_BITS,

    parameter H_VISIBLE,
    parameter H_FRONT_PORCH,
    parameter H_SYNC_PULSE,
    parameter H_BACK_PORCH,
    parameter H_WHOLE_LINE,

    parameter V_VISIBLE,
    parameter V_FRONT_PORCH,
    parameter V_SYNC_PULSE,
    parameter V_BACK_PORCH,
    parameter V_WHOLE_FRAME,

    parameter AXI_ADDR_WIDTH,
    parameter AXI_DATA_WIDTH,

    localparam FB_X_BITS  = $clog2(H_VISIBLE),
    localparam FB_Y_BITS  = $clog2(V_VISIBLE),
    localparam COLOR_BITS = PIXEL_BITS / 3
) (
    input logic clk,
    input logic pixel_clk,
    input logic reset,

    // gfx signals
    input  logic [ FB_X_BITS-1:0] gfx_x,
    input  logic [ FB_Y_BITS-1:0] gfx_y,
    input  logic [PIXEL_BITS-1:0] gfx_color,
    input  logic [ META_BITS-1:0] gfx_meta,
    input  logic                  gfx_valid,
    output logic                  gfx_ready,
    output logic                  gfx_vsync,

    // vga signals
    input  logic                  vga_enable,
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
  //
  // gfx axi writter
  //
  logic [        AXI_ADDR_WIDTH-1:0] gfx_axi_awaddr;
  logic                              gfx_axi_awvalid;
  logic                              gfx_axi_awready;
  logic [        AXI_DATA_WIDTH-1:0] gfx_axi_wdata;
  logic                              gfx_axi_wvalid;
  logic                              gfx_axi_wready;
  logic                              gfx_axi_bready;
  logic                              gfx_axi_bvalid;
  logic [((AXI_DATA_WIDTH+7)/8)-1:0] gfx_axi_wstrb;
  logic [                       1:0] gfx_axi_bresp;

  logic                              gfx_axi_arvalid = 0;

  // verilator lint_off UNUSEDSIGNAL
  // verilator lint_off UNDRIVEN
  logic [        AXI_ADDR_WIDTH-1:0] gfx_axi_araddr;
  logic                              gfx_axi_arready;
  logic [        AXI_DATA_WIDTH-1:0] gfx_axi_rdata;
  logic                              gfx_axi_rvalid;
  logic                              gfx_axi_rready;
  logic [                       1:0] gfx_axi_rresp;
  // verilator lint_on UNUSEDSIGNAL
  // verilator lint_on UNDRIVEN

  //
  // disp axi reader
  //
  logic [        AXI_ADDR_WIDTH-1:0] disp_axi_araddr;
  logic                              disp_axi_arvalid;
  logic                              disp_axi_arready;
  logic [        AXI_DATA_WIDTH-1:0] disp_axi_rdata;
  logic                              disp_axi_rvalid;
  logic                              disp_axi_rready;
  logic [                       1:0] disp_axi_rresp;

  logic                              disp_axi_awvalid = 0;
  logic                              disp_axi_wvalid = 0;

  // verilator lint_off UNUSEDSIGNAL
  // verilator lint_off UNDRIVEN
  logic [        AXI_ADDR_WIDTH-1:0] disp_axi_awaddr;
  logic                              disp_axi_awready;
  logic [        AXI_DATA_WIDTH-1:0] disp_axi_wdata;
  logic                              disp_axi_wready;
  logic                              disp_axi_bready;
  logic [((AXI_DATA_WIDTH+7)/8)-1:0] disp_axi_wstrb;
  logic [                       1:0] disp_axi_bresp;
  logic                              disp_axi_bvalid;
  // verilator lint_on UNUSEDSIGNAL
  // verilator lint_on UNDRIVEN

  //
  // fader/blanker axi writer
  //
  // verilator lint_off UNUSEDSIGNAL
  // verilator lint_off UNDRIVEN
  logic [        AXI_ADDR_WIDTH-1:0] fade_axi_araddr;
  logic                              fade_axi_arvalid = 0;
  logic                              fade_axi_arready;
  logic [        AXI_DATA_WIDTH-1:0] fade_axi_rdata;
  logic                              fade_axi_rvalid;
  logic                              fade_axi_rready;
  logic [                       1:0] fade_axi_rresp;

  logic                              fade_axi_awvalid = 0;
  logic                              fade_axi_wvalid = 0;

  logic [        AXI_ADDR_WIDTH-1:0] fade_axi_awaddr;
  logic                              fade_axi_awready;
  logic [        AXI_DATA_WIDTH-1:0] fade_axi_wdata;
  logic                              fade_axi_wready;
  logic                              fade_axi_bready;
  logic [((AXI_DATA_WIDTH+7)/8)-1:0] fade_axi_wstrb;
  logic [                       1:0] fade_axi_bresp;
  logic                              fade_axi_bvalid;
  // verilator lint_on UNUSEDSIGNAL
  // verilator lint_off UNDRIVEN

  axi_sram_3to2 #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) axi_sram_3to2_inst (
      .axi_clk   (clk),
      .axi_resetn(~reset),

      .in0_axi_awaddr (gfx_axi_awaddr),
      .in0_axi_awvalid(gfx_axi_awvalid),
      .in0_axi_awready(gfx_axi_awready),
      .in0_axi_wdata  (gfx_axi_wdata),
      .in0_axi_wstrb  (gfx_axi_wstrb),
      .in0_axi_wvalid (gfx_axi_wvalid),
      .in0_axi_wready (gfx_axi_wready),
      .in0_axi_bresp  (gfx_axi_bresp),
      .in0_axi_bvalid (gfx_axi_bvalid),
      .in0_axi_bready (gfx_axi_bready),
      .in0_axi_araddr (gfx_axi_araddr),
      .in0_axi_arvalid(gfx_axi_arvalid),
      .in0_axi_arready(gfx_axi_arready),
      .in0_axi_rdata  (gfx_axi_rdata),
      .in0_axi_rresp  (gfx_axi_rresp),
      .in0_axi_rvalid (gfx_axi_rvalid),
      .in0_axi_rready (gfx_axi_rready),

      .in1_axi_awaddr (disp_axi_awaddr),
      .in1_axi_awvalid(disp_axi_awvalid),
      .in1_axi_awready(disp_axi_awready),
      .in1_axi_wdata  (disp_axi_wdata),
      .in1_axi_wstrb  (disp_axi_wstrb),
      .in1_axi_wvalid (disp_axi_wvalid),
      .in1_axi_wready (disp_axi_wready),
      .in1_axi_bresp  (disp_axi_bresp),
      .in1_axi_bvalid (disp_axi_bvalid),
      .in1_axi_bready (disp_axi_bready),
      .in1_axi_araddr (disp_axi_araddr),
      .in1_axi_arvalid(disp_axi_arvalid),
      .in1_axi_arready(disp_axi_arready),
      .in1_axi_rdata  (disp_axi_rdata),
      .in1_axi_rresp  (disp_axi_rresp),
      .in1_axi_rvalid (disp_axi_rvalid),
      .in1_axi_rready (disp_axi_rready),

      .in2_axi_awaddr (fade_axi_awaddr),
      .in2_axi_awvalid(fade_axi_awvalid),
      .in2_axi_awready(fade_axi_awready),
      .in2_axi_wdata  (fade_axi_wdata),
      .in2_axi_wstrb  (fade_axi_wstrb),
      .in2_axi_wvalid (fade_axi_wvalid),
      .in2_axi_wready (fade_axi_wready),
      .in2_axi_bresp  (fade_axi_bresp),
      .in2_axi_bvalid (fade_axi_bvalid),
      .in2_axi_bready (fade_axi_bready),
      .in2_axi_araddr (fade_axi_araddr),
      .in2_axi_arvalid(fade_axi_arvalid),
      .in2_axi_arready(fade_axi_arready),
      .in2_axi_rdata  (fade_axi_rdata),
      .in2_axi_rresp  (fade_axi_rresp),
      .in2_axi_rvalid (fade_axi_rvalid),
      .in2_axi_rready (fade_axi_rready),

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

  // fb writer axi flow control signals
  logic                            fbw_axi_tvalid;
  logic                            fbw_axi_tready;

  // and the data that goes with them
  logic [      AXI_ADDR_WIDTH-1:0] fbw_addr;
  logic [PIXEL_BITS+META_BITS-1:0] fbw_color;

  assign gfx_ready      = fbw_axi_tready;
  assign fbw_axi_tvalid = gfx_valid;
  assign fbw_addr       = (H_VISIBLE * gfx_y + gfx_x);
  assign fbw_color      = {gfx_color, gfx_meta};

  fb_writer #(
      .PIXEL_BITS    (PIXEL_BITS + META_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) fb_writer_inst (
      .clk  (clk),
      .reset(reset),

      .axi_tvalid(fbw_axi_tvalid),
      .axi_tready(fbw_axi_tready),

      .addr (fbw_addr),
      .color(fbw_color),

      .sram_axi_awaddr (gfx_axi_awaddr),
      .sram_axi_awvalid(gfx_axi_awvalid),
      .sram_axi_awready(gfx_axi_awready),
      .sram_axi_wdata  (gfx_axi_wdata),
      .sram_axi_wstrb  (gfx_axi_wstrb),
      .sram_axi_wvalid (gfx_axi_wvalid),
      .sram_axi_wready (gfx_axi_wready),
      .sram_axi_bvalid (gfx_axi_bvalid),
      .sram_axi_bready (gfx_axi_bready),
      .sram_axi_bresp  (gfx_axi_bresp)
  );

  //
  // VGA pixel stream
  //

  // control signals
  logic                  vga_fb_enable;
  logic                  vga_fb_valid;

  // sync signals
  logic                  vga_fb_vsync;
  logic                  vga_fb_hsync;

  // color signals
  logic [COLOR_BITS-1:0] vga_fb_red;
  logic [COLOR_BITS-1:0] vga_fb_grn;
  logic [COLOR_BITS-1:0] vga_fb_blu;
  logic [ META_BITS-1:0] vga_fb_meta;


  assign vga_fb_enable = vga_enable & !fifo_almost_full;

  vga_fb_pixel_stream #(
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
  ) vga_fb_pixel_stream_inst (
      .clk   (clk),
      .reset (reset),
      .enable(vga_fb_enable),
      .valid (vga_fb_valid),
      .hsync (vga_fb_hsync),
      .vsync (vga_fb_vsync),
      .red   (vga_fb_red),
      .grn   (vga_fb_grn),
      .blu   (vga_fb_blu),
      .meta  (vga_fb_meta),

      .sram_axi_araddr (disp_axi_araddr),
      .sram_axi_arvalid(disp_axi_arvalid),
      .sram_axi_arready(disp_axi_arready),
      .sram_axi_rdata  (disp_axi_rdata),
      .sram_axi_rready (disp_axi_rready),
      .sram_axi_rresp  (disp_axi_rresp),
      .sram_axi_rvalid (disp_axi_rvalid)
  );

  // pass vsync back to the gfx caller in case they need it
  assign gfx_vsync = vga_fb_vsync;

  //
  // CDC over to the VGA output clock domain
  //

  // fifo control signals
  logic fifo_almost_full;
  // verilator lint_off UNUSEDSIGNAL
  logic fifo_full;
  logic fifo_empty;
  // verilator lint_on UNUSEDSIGNAL
  logic fifo_r_inc;

  // on the vga side, it's just always reading
  assign fifo_r_inc = 1'b1;

  //
  // VGA data marshaling and unmarshaling on for going in and out of the fifo.
  //
  // fifo_fb_ comes from the frame buffer and is in the writer clock domain.
  // fifo_vga_ is used by the vga side and is in the reader clock domain.
  //
  localparam VGA_DATA_WIDTH = PIXEL_BITS + META_BITS + 2;

  logic [VGA_DATA_WIDTH-1:0] fifo_fb_data;
  logic [VGA_DATA_WIDTH-1:0] fifo_vga_data;

  assign fifo_fb_data = {
    vga_fb_hsync, vga_fb_vsync, vga_fb_red, vga_fb_grn, vga_fb_blu, vga_fb_meta
  };

  assign {vga_hsync, vga_vsync, vga_red, vga_grn, vga_blu, vga_meta} =
      fifo_vga_data;

  // ship it
  cdc_fifo #(
      .DATA_WIDTH     (VGA_DATA_WIDTH),
      .ADDR_SIZE      (4),
      .ALMOST_FULL_BUF(8)
  ) fifo (
      // Write clock domain
      .w_clk        (clk),
      .w_rst_n      (~reset),
      .w_inc        (vga_fb_valid),
      .w_data       (fifo_fb_data),
      .w_full       (fifo_full),
      .w_almost_full(fifo_almost_full),

      .r_clk  (pixel_clk),
      .r_rst_n(~reset),
      .r_inc  (fifo_r_inc),

      // Read clock domain outputs
      .r_empty(fifo_empty),
      .r_data (fifo_vga_data)
  );

endmodule

`endif
