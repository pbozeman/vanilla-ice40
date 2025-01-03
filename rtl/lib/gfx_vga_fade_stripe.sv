`ifndef GFX_VGA_FADE_STRIPE_V
`define GFX_VGA_FADE_STRIPE_V

//
// Single FB GFX display with fading
//
// A large amount of this file is shared with the gfx_vga and gfx_vga_dbuf versions.
// See the TODO there about a potential refactor.

`include "directives.sv"

`include "axi_skidbuf.sv"
`include "axi_sram_controller.sv"
`include "axi_stripe_writer.sv"
`include "cdc_fifo.sv"
`include "fb_writer_2to1.sv"
`include "vga_fb_pixel_stream_striped.sv"
`include "vga_mode.sv"

module gfx_vga_fade_stripe #(
    parameter NUM_S      = 2,
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

    // vga signals
    input  logic                  vga_enable,
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
  localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8;
  localparam PIXEL_AGE_BITS = 3;
  localparam FADING_PIXEL_BITS = PIXEL_BITS + PIXEL_AGE_BITS;

  //
  // gfx axi writter
  //
  logic [        AXI_ADDR_WIDTH-1:0]                     gfx_axi_awaddr;
  logic                                                  gfx_axi_awvalid;
  logic                                                  gfx_axi_awready;
  logic [        AXI_DATA_WIDTH-1:0]                     gfx_axi_wdata;
  logic                                                  gfx_axi_wvalid;
  logic                                                  gfx_axi_wready;
  logic                                                  gfx_axi_bready;
  logic                                                  gfx_axi_bvalid;
  logic [((AXI_DATA_WIDTH+7)/8)-1:0]                     gfx_axi_wstrb;
  logic [                       1:0]                     gfx_axi_bresp;

  // Output AXI interface
  logic [                 NUM_S-1:0][AXI_ADDR_WIDTH-1:0] fb_axi_awaddr;
  logic [                 NUM_S-1:0]                     fb_axi_awvalid;
  logic [                 NUM_S-1:0]                     fb_axi_awready;
  logic [                 NUM_S-1:0][AXI_DATA_WIDTH-1:0] fb_axi_wdata;
  logic [                 NUM_S-1:0][AXI_STRB_WIDTH-1:0] fb_axi_wstrb;
  logic [                 NUM_S-1:0]                     fb_axi_wvalid;
  logic [                 NUM_S-1:0]                     fb_axi_wready;
  logic [                 NUM_S-1:0][               1:0] fb_axi_bresp;
  logic [                 NUM_S-1:0]                     fb_axi_bvalid;
  logic [                 NUM_S-1:0]                     fb_axi_bready;
  logic [                 NUM_S-1:0][AXI_ADDR_WIDTH-1:0] fb_axi_araddr;
  logic [                 NUM_S-1:0]                     fb_axi_arvalid;
  logic [                 NUM_S-1:0]                     fb_axi_arready;
  logic [                 NUM_S-1:0][AXI_DATA_WIDTH-1:0] fb_axi_rdata;
  logic [                 NUM_S-1:0][               1:0] fb_axi_rresp;
  logic [                 NUM_S-1:0]                     fb_axi_rvalid;
  logic [                 NUM_S-1:0]                     fb_axi_rready;

  // sram axi interface
  logic [                 NUM_S-1:0][AXI_ADDR_WIDTH-1:0] sram_axi_awaddr;
  logic [                 NUM_S-1:0]                     sram_axi_awvalid;
  logic [                 NUM_S-1:0]                     sram_axi_awready;
  logic [                 NUM_S-1:0][AXI_DATA_WIDTH-1:0] sram_axi_wdata;
  logic [                 NUM_S-1:0][AXI_STRB_WIDTH-1:0] sram_axi_wstrb;
  logic [                 NUM_S-1:0]                     sram_axi_wvalid;
  logic [                 NUM_S-1:0]                     sram_axi_wready;
  logic [                 NUM_S-1:0][               1:0] sram_axi_bresp;
  logic [                 NUM_S-1:0]                     sram_axi_bvalid;
  logic [                 NUM_S-1:0]                     sram_axi_bready;
  logic [                 NUM_S-1:0][AXI_ADDR_WIDTH-1:0] sram_axi_araddr;
  logic [                 NUM_S-1:0]                     sram_axi_arvalid;
  logic [                 NUM_S-1:0]                     sram_axi_arready;
  logic [                 NUM_S-1:0][AXI_DATA_WIDTH-1:0] sram_axi_rdata;
  logic [                 NUM_S-1:0][               1:0] sram_axi_rresp;
  logic [                 NUM_S-1:0]                     sram_axi_rvalid;
  logic [                 NUM_S-1:0]                     sram_axi_rready;


  for (genvar i = 0; i < NUM_S; i++) begin : gen_s_modules
    axi_sram_controller #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi_sram_ctrl_i (
        .axi_clk     (clk),
        .axi_resetn  (~reset),
        .axi_awaddr  (sram_axi_awaddr[i]),
        .axi_awvalid (sram_axi_awvalid[i]),
        .axi_awready (sram_axi_awready[i]),
        .axi_wdata   (sram_axi_wdata[i]),
        .axi_wstrb   (sram_axi_wstrb[i]),
        .axi_wvalid  (sram_axi_wvalid[i]),
        .axi_wready  (sram_axi_wready[i]),
        .axi_bresp   (sram_axi_bresp[i]),
        .axi_bvalid  (sram_axi_bvalid[i]),
        .axi_bready  (sram_axi_bready[i]),
        .axi_araddr  (sram_axi_araddr[i]),
        .axi_arvalid (sram_axi_arvalid[i]),
        .axi_arready (sram_axi_arready[i]),
        .axi_rdata   (sram_axi_rdata[i]),
        .axi_rresp   (sram_axi_rresp[i]),
        .axi_rvalid  (sram_axi_rvalid[i]),
        .axi_rready  (sram_axi_rready[i]),
        .sram_io_addr(sram_io_addr[i]),
        .sram_io_data(sram_io_data[i]),
        .sram_io_we_n(sram_io_we_n[i]),
        .sram_io_oe_n(sram_io_oe_n[i]),
        .sram_io_ce_n(sram_io_ce_n[i])
    );

    axi_skidbuf #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi_skidbuf_i (
        .axi_clk   (clk),
        .axi_resetn(~reset),

        .s_axi_awaddr (fb_axi_awaddr[i]),
        .s_axi_awvalid(fb_axi_awvalid[i]),
        .s_axi_awready(fb_axi_awready[i]),
        .s_axi_wdata  (fb_axi_wdata[i]),
        .s_axi_wstrb  (fb_axi_wstrb[i]),
        .s_axi_wvalid (fb_axi_wvalid[i]),
        .s_axi_wready (fb_axi_wready[i]),
        .s_axi_bresp  (fb_axi_bresp[i]),
        .s_axi_bvalid (fb_axi_bvalid[i]),
        .s_axi_bready (fb_axi_bready[i]),
        .s_axi_araddr (fb_axi_araddr[i]),
        .s_axi_arvalid(fb_axi_arvalid[i]),
        .s_axi_arready(fb_axi_arready[i]),
        .s_axi_rdata  (fb_axi_rdata[i]),
        .s_axi_rresp  (fb_axi_rresp[i]),
        .s_axi_rvalid (fb_axi_rvalid[i]),
        .s_axi_rready (fb_axi_rready[i]),

        .m_axi_awaddr (sram_axi_awaddr[i]),
        .m_axi_awvalid(sram_axi_awvalid[i]),
        .m_axi_awready(sram_axi_awready[i]),
        .m_axi_wdata  (sram_axi_wdata[i]),
        .m_axi_wstrb  (sram_axi_wstrb[i]),
        .m_axi_wvalid (sram_axi_wvalid[i]),
        .m_axi_wready (sram_axi_wready[i]),
        .m_axi_bresp  (sram_axi_bresp[i]),
        .m_axi_bvalid (sram_axi_bvalid[i]),
        .m_axi_bready (sram_axi_bready[i]),
        .m_axi_araddr (sram_axi_araddr[i]),
        .m_axi_arvalid(sram_axi_arvalid[i]),
        .m_axi_arready(sram_axi_arready[i]),
        .m_axi_rdata  (sram_axi_rdata[i]),
        .m_axi_rresp  (sram_axi_rresp[i]),
        .m_axi_rvalid (sram_axi_rvalid[i]),
        .m_axi_rready (sram_axi_rready[i])
    );
  end

  axi_stripe_writer #(
      .NUM_S         (NUM_S),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) axi_stripe_writer_i (
      .axi_clk   (clk),
      .axi_resetn(~reset),

      .s_axi_awaddr (gfx_axi_awaddr),
      .s_axi_awvalid(gfx_axi_awvalid),
      .s_axi_awready(gfx_axi_awready),
      .s_axi_wdata  (gfx_axi_wdata),
      .s_axi_wstrb  (gfx_axi_wstrb),
      .s_axi_wvalid (gfx_axi_wvalid),
      .s_axi_wready (gfx_axi_wready),
      .s_axi_bresp  (gfx_axi_bresp),
      .s_axi_bvalid (gfx_axi_bvalid),
      .s_axi_bready (gfx_axi_bready),

      .m_axi_awaddr (fb_axi_awaddr),
      .m_axi_awvalid(fb_axi_awvalid),
      .m_axi_awready(fb_axi_awready),
      .m_axi_wdata  (fb_axi_wdata),
      .m_axi_wstrb  (fb_axi_wstrb),
      .m_axi_wvalid (fb_axi_wvalid),
      .m_axi_wready (fb_axi_wready),
      .m_axi_bresp  (fb_axi_bresp),
      .m_axi_bvalid (fb_axi_bvalid),
      .m_axi_bready (fb_axi_bready)
  );

  //
  // VGA pixel stream
  //

  // control signals
  logic                         vga_fb_enable;
  logic                         vga_fb_valid;

  // sync signals
  logic                         vga_fb_vsync;
  logic                         vga_fb_hsync;

  // color signals
  logic [FADING_PIXEL_BITS-1:0] vga_fb_data;
  logic [   PIXEL_AGE_BITS-1:0] vga_fb_age;
  logic [       PIXEL_BITS-1:0] vga_fb_color;
  assign {vga_fb_age, vga_fb_color} = vga_fb_data;

  // pixel addr
  logic [AXI_ADDR_WIDTH-1:0] vga_fb_addr;

  assign vga_fb_enable = (vga_enable &&
                          (!fifo_almost_full && !fade_fifo_w_almost_full));

  vga_fb_pixel_stream_striped #(
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

      .PIXEL_BITS(FADING_PIXEL_BITS)
  ) vga_fb_pixel_stream_inst (
      .clk    (clk),
      .reset  (reset),
      .enable (vga_fb_enable),
      .valid  (vga_fb_valid),
      .hsync  (vga_fb_hsync),
      .vsync  (vga_fb_vsync),
      .visible(),
      .color  (vga_fb_data),
      .addr   (vga_fb_addr),

      .fb_axi_araddr (fb_axi_araddr),
      .fb_axi_arvalid(fb_axi_arvalid),
      .fb_axi_arready(fb_axi_arready),
      .fb_axi_rdata  (fb_axi_rdata),
      .fb_axi_rready (fb_axi_rready),
      .fb_axi_rresp  (fb_axi_rresp),
      .fb_axi_rvalid (fb_axi_rvalid)
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
  localparam VGA_DATA_WIDTH = PIXEL_BITS + 2;

  logic [VGA_DATA_WIDTH-1:0] fifo_fb_data;
  logic [VGA_DATA_WIDTH-1:0] fifo_vga_data;

  always_comb begin
    fifo_fb_data = {vga_fb_hsync, vga_fb_vsync, vga_fb_color};
  end

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
  // Fading follows the pixel we just read from the fb.
  //
  localparam FADE_FIFO_DATA_WIDTH = AXI_ADDR_WIDTH + FADING_PIXEL_BITS;

  logic                            fade_fifo_w_inc;
  logic [FADE_FIFO_DATA_WIDTH-1:0] fade_fifo_w_data;
  logic                            fade_fifo_w_almost_full;
  // verilator lint_off UNUSEDSIGNAL
  logic                            fade_fifo_w_full;
  // verilator lint_on UNUSEDSIGNAL
  logic                            fade_fifo_r_inc;
  logic [FADE_FIFO_DATA_WIDTH-1:0] fade_fifo_r_data;
  logic                            fade_fifo_r_empty;

  //
  // pipeline fading calc to meet timing
  //
  // Since the caller is slower than the writer and we aren't using the fifo
  // backpressure, it's easier to do this on this side of the fifo.
  // We are missing skid buffers necessary to register axi backpressure
  // on the other side of the fifo.
  //
  logic                            fade_fifo_w_inc_p1;
  logic [FADE_FIFO_DATA_WIDTH-1:0] fade_fifo_w_data_p1;

  logic [          PIXEL_BITS-1:0] next_vga_fb_color;
  logic [      PIXEL_AGE_BITS-1:0] next_vga_fb_age;

  logic [          COLOR_BITS-1:0] vga_fb_red;
  logic [          COLOR_BITS-1:0] vga_fb_grn;
  logic [          COLOR_BITS-1:0] vga_fb_blu;

  assign {vga_fb_red, vga_fb_grn, vga_fb_blu} = vga_fb_color;

  always_comb begin
    next_vga_fb_age = 0;

    if (vga_fb_age > 0) begin
      next_vga_fb_age = vga_fb_age - 1;
    end
  end

  always_comb begin
    // TODO: more advanced fading, also, clean up the constants
    if (next_vga_fb_age == PIXEL_AGE_BITS'(2)) begin
      next_vga_fb_color = {vga_fb_red >> 1, vga_fb_grn >> 1, vga_fb_blu >> 1};
    end else begin
      next_vga_fb_color = {vga_fb_red, vga_fb_grn, vga_fb_blu};
    end
  end

  always_comb begin
    fade_fifo_w_data = {
      vga_fb_addr,
      next_vga_fb_age,
      (next_vga_fb_age > 0 ? next_vga_fb_color : '0)
    };
  end

  assign fade_fifo_w_inc = vga_fb_valid && |vga_fb_color && (vga_fb_age > 0);

  always_ff @(posedge clk) begin
    fade_fifo_w_inc_p1  <= fade_fifo_w_inc;
    fade_fifo_w_data_p1 <= fade_fifo_w_data;
  end

  sync_fifo #(
      .DATA_WIDTH     (FADE_FIFO_DATA_WIDTH),
      .ADDR_SIZE      (3),
      .ALMOST_FULL_BUF(4)
  ) fade_fifo (
      .clk          (clk),
      .rst_n        (~reset),
      .w_inc        (fade_fifo_w_inc_p1),
      .w_data       (fade_fifo_w_data_p1),
      .w_full       (fade_fifo_w_full),
      .w_almost_full(fade_fifo_w_almost_full),
      .r_inc        (fade_fifo_r_inc),
      .r_data       (fade_fifo_r_data),
      .r_empty      (fade_fifo_r_empty)
  );

  logic [FADE_FIFO_DATA_WIDTH-1:0] fade_fifo_r_data_p1;
  logic                            fade_fifo_r_empty_p1;
  always_ff @(posedge clk) begin
    fade_fifo_r_data_p1  <= fade_fifo_r_data;
    fade_fifo_r_empty_p1 <= fade_fifo_r_empty;
  end

  // fade writer axi flow control signals
  logic                         fw_axi_tvalid;
  logic                         fw_axi_tready;

  // and the data that goes with them
  logic [   AXI_ADDR_WIDTH-1:0] fw_addr;
  logic [FADING_PIXEL_BITS-1:0] fw_color;

  assign fade_fifo_r_inc = fw_axi_tready;
  assign fw_axi_tvalid   = !fade_fifo_r_empty_p1;

  always_comb begin
    {fw_addr, fw_color} = fade_fifo_r_data_p1;
  end

  //
  // gfx writer
  //

  // gfx writer axi flow control signals
  logic                         gw_axi_tvalid;
  logic                         gw_axi_tready;

  // and the data that goes with them
  logic [   AXI_ADDR_WIDTH-1:0] gw_addr;
  logic [FADING_PIXEL_BITS-1:0] gw_color;

  assign gfx_ready = (gw_axi_tready && !fade_fifo_w_almost_full &&
                      !fifo_almost_full);
  assign gw_axi_tvalid = gfx_valid;
  assign gw_addr = H_VISIBLE * gfx_y + AXI_ADDR_WIDTH'(gfx_x);
  assign gw_color = {PIXEL_AGE_BITS'(4), gfx_color};

  fb_writer_2to1 #(
      .PIXEL_BITS    (FADING_PIXEL_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) fb_writer_2to1_inst (
      .clk  (clk),
      .reset(reset),

      .in0_axi_tvalid(fw_axi_tvalid),
      .in0_axi_tready(fw_axi_tready),
      .in0_addr      (fw_addr),
      .in0_color     (fw_color),

      .in1_axi_tvalid(gw_axi_tvalid),
      .in1_axi_tready(gw_axi_tready),
      .in1_addr      (gw_addr),
      .in1_color     (gw_color),

      .axi_awaddr (gfx_axi_awaddr),
      .axi_awvalid(gfx_axi_awvalid),
      .axi_awready(gfx_axi_awready),
      .axi_wdata  (gfx_axi_wdata),
      .axi_wstrb  (gfx_axi_wstrb),
      .axi_wvalid (gfx_axi_wvalid),
      .axi_wready (gfx_axi_wready),
      .axi_bvalid (gfx_axi_bvalid),
      .axi_bready (gfx_axi_bready),
      .axi_bresp  (gfx_axi_bresp)
  );

endmodule

`endif
