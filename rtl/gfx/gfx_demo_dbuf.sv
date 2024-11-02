`ifndef GFX_DEMO_DBUF_V
`define GFX_DEMO_DBUF_V


`include "directives.sv"

`include "axi_sram_dbuf_controller.sv"
`include "cdc_fifo.sv"
`include "delay.sv"
`include "detect_falling.sv"
`include "detect_rising.sv"
`include "fb_writer.sv"
`include "gfx_test_pattern.sv"
`include "vga_fb_pixel_stream.sv"
`include "vga_mode.sv"

// verilator lint_off UNUSEDSIGNAL
module gfx_demo_dbuf #(
    parameter VGA_WIDTH      = `VGA_MODE_H_VISIBLE,
    parameter VGA_HEIGHT     = `VGA_MODE_V_VISIBLE,
    parameter PIXEL_BITS     = 12,
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

  logic                              mem_switch;

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
  logic [ FB_X_BITS-1:0] gfx_x;
  logic [ FB_Y_BITS-1:0] gfx_y;
  logic [PIXEL_BITS-1:0] gfx_color;
  logic                  gfx_inc;
  logic                  gfx_last;
  logic                  gfx_valid;

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

  // fb writer axi flow control signals
  logic                      fbw_axi_tvalid;
  logic                      fbw_axi_tready;

  // and the data that goes with them
  logic [AXI_ADDR_WIDTH-1:0] fbw_addr;
  logic [    PIXEL_BITS-1:0] fbw_color;

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

  logic [AXI_ADDR_WIDTH-1:0] gfx_addr;
  assign gfx_inc  = (fbw_axi_tready & fbw_axi_tvalid);
  assign gfx_addr = (VGA_WIDTH * gfx_y + gfx_x);

  // fb writer data
  always_ff @(posedge clk) begin
    if (reset) begin
      fbw_axi_tvalid <= 1'b0;
    end else begin
      if (gfx_valid) begin
        fbw_axi_tvalid <= 1'b1;
      end else begin
        if (fbw_axi_tvalid & fbw_axi_tready) begin
          fbw_axi_tvalid <= 1'b0;
        end
      end
    end
  end

  // fb writer data
  always_ff @(posedge clk) begin
    if (gfx_valid) begin
      fbw_color <= gfx_color;
      fbw_addr  <= gfx_addr;
    end
  end

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
  logic [    COLOR_BITS-1:0] vga_fb_red;
  logic [    COLOR_BITS-1:0] vga_fb_grn;
  logic [    COLOR_BITS-1:0] vga_fb_blu;

  logic [AXI_ADDR_WIDTH-1:0] xxx_addr;

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
  localparam VGA_DATA_WIDTH = 14;

  logic [VGA_DATA_WIDTH-1:0] fifo_fb_data;
  logic [VGA_DATA_WIDTH-1:0] fifo_vga_data;

  assign fifo_fb_data = {
    vga_fb_hsync, vga_fb_vsync, vga_fb_red, vga_fb_grn, vga_fb_blu
  };

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

  // Track when the first frame is done and use it to switch the first time
  //
  // TODO: This is a bit of a hack. The writer may say they are done, but there
  // might be writes in flight. If so, we can't switch. Work this into the
  // switcher, or give the writers a way to track writes, or something.
  // For now, just make it work while the basic functionality is fleshed out.
  logic gfx_last_d;
  delay #(
      .DELAY_CYCLES(4)
  ) delay_inst (
      .clk(clk),
      .in (gfx_last),
      .out(gfx_last_d)
  );

  logic gfx_ready = 0;
  always_ff @(posedge clk) begin
    if (!gfx_ready) begin
      gfx_ready <= gfx_last_d;
    end
  end

  logic posedge_gfx_ready;
  detect_rising rising_pattern_done (
      .clk     (clk),
      .signal  (gfx_ready),
      .detected(posedge_gfx_ready)
  );

  logic negedge_vsync;
  detect_falling falling_sram_vga_vsync (
      .clk     (clk),
      .signal  (vga_fb_vsync),
      .detected(negedge_vsync)
  );

  assign mem_switch    = posedge_gfx_ready | negedge_vsync;
  assign vga_fb_enable = gfx_ready & !fifo_almost_full;

endmodule
// verilator lint_on UNUSEDSIGNAL

`endif
