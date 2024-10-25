`ifndef GFX_DEMO_V
`define GFX_DEMO_V


`include "directives.v"

`include "axi_sram_dbuf_controller.v"
`include "detect_rising.v"
`include "fb_writer.v"
`include "gfx_test_pattern.v"
`include "vga_fb_pixel_stream.v"

// verilator lint_off UNUSEDSIGNAL
module gfx_demo #(
    parameter VGA_WIDTH      = 640,
    parameter VGA_HEIGHT     = 480,
    parameter PIXEL_BITS     = 12,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input wire clk,
    input wire reset,

    output wire [AXI_ADDR_WIDTH-1:0] addr,
    output wire [    PIXEL_BITS-1:0] color,

    // sram0 controller to io pins
    output wire [AXI_ADDR_WIDTH-1:0] sram0_io_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram0_io_data,
    output wire                      sram0_io_we_n,
    output wire                      sram0_io_oe_n,
    output wire                      sram0_io_ce_n,

    // sram1 controller to io pins
    output wire [AXI_ADDR_WIDTH-1:0] sram1_io_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram1_io_data,
    output wire                      sram1_io_we_n,
    output wire                      sram1_io_oe_n,
    output wire                      sram1_io_ce_n
);
  localparam FB_X_BITS = $clog2(VGA_WIDTH);
  localparam FB_Y_BITS = $clog2(VGA_HEIGHT);

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

  wire                              mem_switch;

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

  // gfx signals
  wire [ FB_X_BITS-1:0] gfx_x;
  wire [ FB_Y_BITS-1:0] gfx_y;
  wire [PIXEL_BITS-1:0] gfx_color;
  wire                  gfx_inc;
  wire                  gfx_last;
  wire                  gfx_valid;

  // TODO: rename u_pat
  gfx_test_pattern u_pat (
      .clk  (clk),
      .reset(reset),
      .inc  (gfx_inc),
      .x    (gfx_x),
      .y    (gfx_y),
      .color(gfx_color),
      .valid(gfx_valid),
      .last (gfx_last)
  );

  // fb writer axi flow control signals
  reg                       fbw_axi_tvalid;
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
  assign gfx_inc  = (fbw_axi_tready & fbw_axi_tvalid);
  assign gfx_addr = (VGA_WIDTH * gfx_y + gfx_x);

  // fb writer data
  always @(posedge clk) begin
    if (reset) begin
      fbw_axi_tvalid <= 1'b0;
    end else begin
      if (gfx_valid) begin
        fbw_addr       <= gfx_addr;
        fbw_color      <= gfx_color;
        fbw_axi_tvalid <= 1'b1;
      end else begin
        if (fbw_axi_tvalid & fbw_axi_tready) begin
          fbw_axi_tvalid <= 1'b0;
        end
      end
    end
  end

  //
  // VGA pixel stream
  //
  localparam COLOR_BITS = PIXEL_BITS / 3;

  // control signals
  wire                      vga_fb_enable;
  wire                      vga_fb_valid;

  // sync signals
  wire                      vga_fb_vsync;
  wire                      vga_fb_hsync;

  // color signals
  wire [    COLOR_BITS-1:0] vga_fb_red;
  wire [    COLOR_BITS-1:0] vga_fb_grn;
  wire [    COLOR_BITS-1:0] vga_fb_blu;

  wire [AXI_ADDR_WIDTH-1:0] xxx_addr;

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
      .sram_axi_rvalid (disp_axi_rvalid),

      .xxx_addr(xxx_addr)
  );

  assign addr  = xxx_addr;
  assign color = fbw_color;

  //
  // FB double buffer switching logic
  //
  // At startup, we wait for the gfx engine to prepare a frame and then
  // we enable the pixel stream. This let's us get a clean signal
  // on the first frame, rather than displaying whatever random stuff
  // is in memory. (Displaying a frame of gunk is probably fine in normal
  // use, but clearing the display or setting a test pattern for the first
  // frame is helpful when looking at signal output with a logic analyzer or
  // scope.)
  //
  // Right now the first frame is just gfx_done from the pattern gen,
  // but later this should be the result of some sort of gfx or fb init
  // module.
  //
  // After the first frame, we switch during vsync, regardless of what the
  // gfx engine wants todo.
  //

  // Track when the first frame is done
  // The _p1 lets the final item get written before switching.
  reg gfx_last_p1;
  reg gfx_ready = 1'b0;
  always @(posedge clk) begin
    if (reset) begin
      gfx_last_p1 <= 1'b0;
      gfx_ready   <= 1'b0;
    end else begin
      gfx_last_p1 <= gfx_last;
      if (!gfx_ready) begin
        gfx_ready <= gfx_last_p1;
      end
    end
  end

  wire posedge_gfx_ready;
  detect_rising rising_pattern_done (
      .clk     (clk),
      .signal  (gfx_ready),
      .detected(posedge_gfx_ready)
  );

  assign mem_switch    = (posedge_gfx_ready);  // | negedge_sram_vga_vsync);
  assign vga_fb_enable = gfx_ready;

endmodule
// verilator lint_on UNUSEDSIGNAL

`endif
