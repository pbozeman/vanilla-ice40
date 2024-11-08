`ifndef GFX_VGA_DBUF_V
`define GFX_VGA_DBUF_V

//
// Double buffer FB GFX display
//
// TODO: there is a large chunk of this copied from the single buffer version.
// If that version continues to exist, then refactor both to share a common
// module. At a quick glance the correct axi controller could be instantiated,
// and the gfx_axi_* and disp_axi_* signals passed to the common module.

`include "directives.sv"

`include "axi_sram_dbuf_controller.sv"
`include "cdc_fifo.sv"
`include "detect_falling.sv"
`include "fb_writer.sv"
`include "vga_mode.sv"
`include "vga_fb_pixel_stream.sv"

module gfx_vga_dbuf #(
    parameter VGA_WIDTH      = `VGA_MODE_H_VISIBLE,
    parameter VGA_HEIGHT     = `VGA_MODE_V_VISIBLE,
    parameter PIXEL_BITS     = 12,
    parameter META_BITS      = 4,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,

    localparam FB_X_BITS  = $clog2(VGA_WIDTH),
    localparam FB_Y_BITS  = $clog2(VGA_HEIGHT),
    localparam COLOR_BITS = PIXEL_BITS / 3
) (
    input logic clk,
    input logic pixel_clk,
    input logic reset,

    input logic mem_switch,

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

  axi_sram_dbuf_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) axi_sram_dbuf_controller_inst (
      // core signals
      .clk  (clk),
      .reset(reset),

      // switch producer/consumer to alternate sram
      .switch(mem_switch),

      // producer interface
      .prod_axi_awaddr (gfx_axi_awaddr),
      .prod_axi_awvalid(gfx_axi_awvalid),
      .prod_axi_awready(gfx_axi_awready),
      .prod_axi_wdata  (gfx_axi_wdata),
      .prod_axi_wvalid (gfx_axi_wvalid),
      .prod_axi_wready (gfx_axi_wready),
      .prod_axi_wstrb  (gfx_axi_wstrb),
      .prod_axi_bready (gfx_axi_bready),
      .prod_axi_bvalid (gfx_axi_bvalid),
      .prod_axi_bresp  (gfx_axi_bresp),

      // consumer interface
      .cons_axi_araddr (disp_axi_araddr),
      .cons_axi_arvalid(disp_axi_arvalid),
      .cons_axi_arready(disp_axi_arready),
      .cons_axi_rdata  (disp_axi_rdata),
      .cons_axi_rvalid (disp_axi_rvalid),
      .cons_axi_rready (disp_axi_rready),
      .cons_axi_rresp  (disp_axi_rresp),

      // sram0 controller to io pins
      .sram0_io_addr(sram0_io_addr),
      .sram0_io_data(sram0_io_data),
      .sram0_io_we_n(sram0_io_we_n),
      .sram0_io_oe_n(sram0_io_oe_n),
      .sram0_io_ce_n(sram0_io_ce_n),

      // sram1 controller to io pins
      .sram1_io_addr(sram1_io_addr),
      .sram1_io_data(sram1_io_data),
      .sram1_io_we_n(sram1_io_we_n),
      .sram1_io_oe_n(sram1_io_oe_n),
      .sram1_io_ce_n(sram1_io_ce_n)
  );

  assign gfx_ready = fbw_axi_tready;

  // fb writer axi flow control signals
  logic                            fbw_axi_tvalid = 0;
  logic                            fbw_axi_tready;

  // and the data that goes with them
  logic [      AXI_ADDR_WIDTH-1:0] fbw_addr;
  logic [PIXEL_BITS+META_BITS-1:0] fbw_color;

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

  logic [AXI_ADDR_WIDTH-1:0] gfx_addr;
  assign gfx_addr = (VGA_WIDTH * gfx_y + gfx_x);

  // fb writer data
  always_ff @(posedge clk) begin
    // icecube2 crashes if we set this on reset.
    // TODO: see if there is a workaround, in the mean time,
    // the value is set to 0 above during bootup.
    if (gfx_valid) begin
      fbw_axi_tvalid <= 1'b1;
    end else begin
      if (fbw_axi_tvalid & fbw_axi_tready) begin
        fbw_axi_tvalid <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (gfx_valid) begin
      fbw_addr <= gfx_addr;
    end
  end

  always_ff @(posedge clk) begin
    if (gfx_valid) begin
      fbw_color <= {gfx_color, gfx_meta};
    end
  end

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
      .PIXEL_BITS    (PIXEL_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
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
