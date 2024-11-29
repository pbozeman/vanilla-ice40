`ifndef GFX_VGA_V
`define GFX_VGA_V

//
// Single FB GFX display
//
// A large amount of this file is shared with the gfx_vga_dbuf version. See
// the TODO there about a potential refactor.

`include "directives.sv"

`include "axi_sram_controller.sv"
`include "cdc_fifo.sv"
`include "fb_writer.sv"
`include "vga_mode.sv"
`include "vga_fb_pixel_stream.sv"

module gfx_vga #(
    parameter PIXEL_BITS = 12,

    parameter H_VISIBLE     = 640,
    parameter H_FRONT_PORCH = 16,
    parameter H_SYNC_PULSE  = 96,
    parameter H_BACK_PORCH  = 48,
    parameter H_WHOLE_LINE  = 800,

    parameter V_VISIBLE     = 640,
    parameter V_FRONT_PORCH = 10,
    parameter V_SYNC_PULSE  = 2,
    parameter V_BACK_PORCH  = 33,
    parameter V_WHOLE_FRAME = 525,

    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,

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
    input  logic                  gfx_valid,
    output logic                  gfx_ready,
    output logic                  gfx_vsync,

    // vga signals
    input  logic                  vga_enable,
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

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) axi_sram_controller_inst (
      // core signals
      .axi_clk   (clk),
      .axi_resetn(~reset),

      // producer interface
      .axi_awaddr (gfx_axi_awaddr),
      .axi_awvalid(gfx_axi_awvalid),
      .axi_awready(gfx_axi_awready),
      .axi_wdata  (gfx_axi_wdata),
      .axi_wvalid (gfx_axi_wvalid),
      .axi_wready (gfx_axi_wready),
      .axi_wstrb  (gfx_axi_wstrb),
      .axi_bready (gfx_axi_bready),
      .axi_bvalid (gfx_axi_bvalid),
      .axi_bresp  (gfx_axi_bresp),

      // consumer interface
      .axi_araddr (disp_axi_araddr),
      .axi_arvalid(disp_axi_arvalid),
      .axi_arready(disp_axi_arready),
      .axi_rdata  (disp_axi_rdata),
      .axi_rvalid (disp_axi_rvalid),
      .axi_rready (disp_axi_rready),
      .axi_rresp  (disp_axi_rresp),

      // sram controller to io pins
      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  // fb writer axi flow control signals
  logic                      fbw_axi_tvalid;
  logic                      fbw_axi_tready;

  // and the data that goes with them
  logic [AXI_ADDR_WIDTH-1:0] fbw_addr;
  logic [    PIXEL_BITS-1:0] fbw_color;

  assign gfx_ready      = fbw_axi_tready;
  assign fbw_axi_tvalid = gfx_valid;
  assign fbw_addr       = (H_VISIBLE * gfx_y + gfx_x);
  assign fbw_color      = gfx_color;

  fb_writer #(
      .PIXEL_BITS    (PIXEL_BITS),
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
  logic                      vga_fb_enable;
  logic                      vga_fb_valid;

  // sync signals
  logic                      vga_fb_vsync;
  logic                      vga_fb_hsync;

  // color signals
  logic [    PIXEL_BITS-1:0] vga_fb_color;

  // pixel addr
  // verilator lint_off UNUSEDSIGNAL
  logic [AXI_ADDR_WIDTH-1:0] vga_fb_addr;
  // verilator lint_on UNUSEDSIGNAL

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

      .PIXEL_BITS(PIXEL_BITS)
  ) vga_fb_pixel_stream_inst (
      .clk   (clk),
      .reset (reset),
      .enable(vga_fb_enable),
      .valid (vga_fb_valid),
      .hsync (vga_fb_hsync),
      .vsync (vga_fb_vsync),
      .color (vga_fb_color),
      .addr  (vga_fb_addr),

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
  localparam VGA_DATA_WIDTH = PIXEL_BITS + 2;

  logic [VGA_DATA_WIDTH-1:0] fifo_fb_data;
  logic [VGA_DATA_WIDTH-1:0] fifo_vga_data;

  assign fifo_fb_data = {vga_fb_hsync, vga_fb_vsync, vga_fb_color};

  assign {vga_hsync, vga_vsync, vga_red, vga_grn, vga_blu} = fifo_vga_data;

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
