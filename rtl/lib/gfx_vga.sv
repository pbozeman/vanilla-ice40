`ifndef GFX_VGA_V
`define GFX_VGA_V

//
// Single FB GFX display
//

`include "directives.sv"

`include "axi_sram_controller.sv"
`include "cdc_fifo.sv"
`include "fb_writer.sv"
`include "vga_mode.sv"
`include "vga_fb_pixel_stream.sv"

module gfx_vga #(
    parameter VGA_WIDTH      = `VGA_MODE_H_VISIBLE,
    parameter VGA_HEIGHT     = `VGA_MODE_V_VISIBLE,
    parameter PIXEL_BITS     = 12,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,

    localparam FB_X_BITS  = $clog2(VGA_WIDTH),
    localparam FB_Y_BITS  = $clog2(VGA_HEIGHT),
    localparam COLOR_BITS = PIXEL_BITS / 3
) (
    input wire clk,
    input wire pixel_clk,
    input wire reset,

    // gfx signals
    input  wire [ FB_X_BITS-1:0] gfx_x,
    input  wire [ FB_Y_BITS-1:0] gfx_y,
    input  wire [PIXEL_BITS-1:0] gfx_color,
    input  wire                  gfx_valid,
    output wire                  gfx_ready,

    // vga signals
    input  wire                  vga_enable,
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
  //
  // gfx axi writter
  //
  wire [        AXI_ADDR_WIDTH-1:0] gfx_axi_awaddr;
  wire                              gfx_axi_awvalid;
  wire                              gfx_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] gfx_axi_wdata;
  wire                              gfx_axi_wvalid;
  wire                              gfx_axi_wready;
  wire                              gfx_axi_bready;
  wire                              gfx_axi_bvalid;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] gfx_axi_wstrb;
  wire [                       1:0] gfx_axi_bresp;

  //
  // disp axi reader
  //
  wire [        AXI_ADDR_WIDTH-1:0] disp_axi_araddr;
  wire                              disp_axi_arvalid;
  wire                              disp_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] disp_axi_rdata;
  wire                              disp_axi_rvalid;
  wire                              disp_axi_rready;
  wire [                       1:0] disp_axi_rresp;

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

  assign gfx_ready = fbw_axi_tready;

  // fb writer axi flow control signals
  reg                       fbw_axi_tvalid = 0;
  wire                      fbw_axi_tready;

  // and the data that goes with them
  reg  [AXI_ADDR_WIDTH-1:0] fbw_addr;
  reg  [    PIXEL_BITS-1:0] fbw_color;

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

  wire [AXI_ADDR_WIDTH-1:0] gfx_addr;
  assign gfx_addr = (VGA_WIDTH * gfx_y + gfx_x);

  // fb writer data
  always @(posedge clk) begin
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

  always @(posedge clk) begin
    if (gfx_valid) begin
      fbw_color <= gfx_color;
      fbw_addr  <= gfx_addr;
    end
  end

  //
  // VGA pixel stream
  //

  // control signals
  wire                  vga_fb_enable;
  wire                  vga_fb_valid;

  // sync signals
  wire                  vga_fb_vsync;
  wire                  vga_fb_hsync;

  // color signals
  wire [COLOR_BITS-1:0] vga_fb_red;
  wire [COLOR_BITS-1:0] vga_fb_grn;
  wire [COLOR_BITS-1:0] vga_fb_blu;


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

      .sram_axi_araddr (disp_axi_araddr),
      .sram_axi_arvalid(disp_axi_arvalid),
      .sram_axi_arready(disp_axi_arready),
      .sram_axi_rdata  (disp_axi_rdata),
      .sram_axi_rready (disp_axi_rready),
      .sram_axi_rresp  (disp_axi_rresp),
      .sram_axi_rvalid (disp_axi_rvalid)
  );

  //
  // CDC over to the VGA output clock domain
  //

  // fifo control signals
  wire fifo_almost_full;
  // verilator lint_off UNUSEDSIGNAL
  wire fifo_full;
  wire fifo_empty;
  // verilator lint_on UNUSEDSIGNAL
  wire fifo_r_inc;

  // on the vga side, it's just always reading
  assign fifo_r_inc = 1'b1;

  //
  // VGA data marshaling and unmarshaling on for going in and out of the fifo.
  //
  // fifo_fb_ comes from the frame buffer and is in the writer clock domain.
  // fifo_vga_ is used by the vga side and is in the reader clock domain.
  //
  localparam VGA_DATA_WIDTH = 14;

  wire [VGA_DATA_WIDTH-1:0] fifo_fb_data;
  wire [VGA_DATA_WIDTH-1:0] fifo_vga_data;

  assign fifo_fb_data = {
    vga_fb_hsync, vga_fb_vsync, vga_fb_red, vga_fb_grn, vga_fb_blu
  };

  assign {vga_hsync, vga_vsync, vga_red, vga_grn, vga_blu} = fifo_vga_data;

  // ship it
  cdc_fifo #(
      .DATA_WIDTH     (VGA_DATA_WIDTH),
      .ADDR_SIZE      (3),
      .ALMOST_FULL_BUF(4)
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
