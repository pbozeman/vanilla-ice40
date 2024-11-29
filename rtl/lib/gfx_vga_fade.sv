`ifndef GFX_VGA_FADE_V
`define GFX_VGA_FADE_V

//
// Single FB GFX display with fading
//
// A large amount of this file is shared with the gfx_vga and gfx_vga_dbuf versions.
// See the TODO there about a potential refactor.

`include "directives.sv"

`include "axi_sram_controller.sv"
`include "cdc_fifo.sv"
`include "detect_rising.sv"
`include "fb_writer_2to1.sv"
`include "gfx_clear.sv"
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
module gfx_vga_fade #(
    parameter PIXEL_BITS = 12,
    parameter META_BITS  = 4,

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

  //
  // Fading follows the pixel we just read from the fb.
  //
  // Or it will, for now, just clear the pixels in a loop as a poc
  // TODO: implement actual fading
  //
  // fade writer axi flow control signals
  logic                            fw_axi_tvalid;
  logic                            fw_axi_tready;

  // and the data that goes with them
  logic [      AXI_ADDR_WIDTH-1:0] fw_addr;
  logic [PIXEL_BITS+META_BITS-1:0] fw_color;

  logic                            clr_pvalid;
  logic                            clr_pready;
  logic [           FB_X_BITS-1:0] clr_x;
  logic [           FB_Y_BITS-1:0] clr_y;
  logic [          PIXEL_BITS-1:0] clr_color;
  logic [           META_BITS-1:0] clr_meta;
  logic                            clr_last;
  logic                            clr_reset;

  // TODO: use this for fading
  assign clr_meta = '0;


  gfx_clear #(
      .FB_WIDTH  (H_VISIBLE),
      .FB_HEIGHT (V_VISIBLE),
      .PIXEL_BITS(PIXEL_BITS)
  ) gfx_clear_inst (
      .clk   (clk),
      .reset (reset || clr_reset),
      .pready(clr_pready),
      .pvalid(clr_pvalid),
      .x     (clr_x),
      .y     (clr_y),
      .color (clr_color),
      .last  (clr_last)
  );

  // This is temporary and still a total hack, but it's the next simplest
  // POC and reduces flicker.
  //
  // Actually, while marginally better than clearing at full speed, this
  // still looks very terrible, but better considering it was a 2 minute
  // implementation. Next up is the proper fading implementation.
  localparam FRAMES_PERSISTENCE = 2;
  logic [$clog2(FRAMES_PERSISTENCE):0] persistence_count;
  logic                                frame_done;

  detect_rising detect_rising_vsync (
      .clk     (clk),
      .signal  (vga_fb_vsync),
      .detected(frame_done)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      persistence_count <= 0;
      clr_reset         <= 1'b0;
    end else begin
      clr_reset <= 1'b0;

      if (clr_last && frame_done) begin
        if (persistence_count == FRAMES_PERSISTENCE) begin
          clr_reset         <= 1'b1;
          persistence_count <= 0;
        end else begin
          persistence_count <= persistence_count + 1;
        end
      end
    end
  end

  assign clr_pready    = fw_axi_tready;
  // assign fw_axi_tvalid = 1'b0;
  assign fw_axi_tvalid = clr_pvalid;

  assign fw_addr       = (H_VISIBLE * clr_y + clr_x);
  assign fw_color      = {clr_color, clr_meta};

  //
  // gfx writer
  //

  // gfx writer axi flow control signals
  logic                            gw_axi_tvalid;
  logic                            gw_axi_tready;

  // and the data that goes with them
  logic [      AXI_ADDR_WIDTH-1:0] gw_addr;
  logic [PIXEL_BITS+META_BITS-1:0] gw_color;

  assign gfx_ready     = gw_axi_tready;
  assign gw_axi_tvalid = gfx_valid;
  assign gw_addr       = (H_VISIBLE * gfx_y + gfx_x);
  assign gw_color      = {gfx_color, gfx_meta};

  fb_writer_2to1 #(
      .PIXEL_BITS    (PIXEL_BITS + META_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) fb_writer_2to1_inst (
      .clk  (clk),
      .reset(reset),

      .in0_axi_tvalid(gw_axi_tvalid),
      .in0_axi_tready(gw_axi_tready),
      .in0_addr      (gw_addr),
      .in0_color     (gw_color),

      .in1_axi_tvalid(fw_axi_tvalid),
      .in1_axi_tready(fw_axi_tready),
      .in1_addr      (fw_addr),
      .in1_color     (fw_color),

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

endmodule

`endif
