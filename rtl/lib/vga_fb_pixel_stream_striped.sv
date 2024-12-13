`ifndef VGA_FB_PIXEL_STREAM_STRIPED_V
`define VGA_FB_PIXEL_STREAM_STRIPED_V

// It might be a bit weird that we are passing in multiple axi controllers
// into this and then constructing a stripe here, but this let's us make
// the minimum changes to the instantiating module as we move from
// a non-striped to a striped version.
//
// Revisit this when the design settles down and maybe even nuke the old one
// prior to a cleanup.
//
// This is a very different implementation than the original pixel stream.
// Rather than just iterating through the addr space, we are going to iterate
// by line. Each visible part of the line is read with an axi_stripe_reader,
// which handles the prefetching for us.

`include "directives.sv"

`include "axi_stripe_readn.sv"
`include "iter.sv"
`include "vga_mode.sv"

module vga_fb_pixel_stream_striped #(
    parameter NUM_S      = 2,
    parameter PIXEL_BITS = 12,

    // verilator lint_off UNUSEDPARAM
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
    // verilator lint_on UNUSEDPARAM

    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input logic clk,
    input logic reset,

    // stream signals
    // TODO: replace with axi like signaling.
    input  logic enable,
    output logic valid,

    // sync signals
    output logic vsync,
    output logic hsync,

    // color
    output logic [PIXEL_BITS-1:0] color,

    // We return addrs so that the instantiating module has the option to
    // modify the pixel after it is sent for display, e.g. to dim pixels
    // when this is being used a fb for a vector to raster converter.
    output logic [AXI_ADDR_WIDTH-1:0] addr,
    output logic                      visible,

    //
    // The AXI interfaces for each stip in the frame buffer.
    output logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] fb_axi_araddr,
    output logic [NUM_S-1:0]                     fb_axi_arvalid,
    input  logic [NUM_S-1:0]                     fb_axi_arready,
    input  logic [NUM_S-1:0]                     fb_axi_rvalid,
    output logic [NUM_S-1:0]                     fb_axi_rready,
    input  logic [NUM_S-1:0][AXI_DATA_WIDTH-1:0] fb_axi_rdata,
    input  logic [NUM_S-1:0][               1:0] fb_axi_rresp
);
  localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
  localparam H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;

  localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
  localparam V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;

  //
  // fb reader
  //
  localparam AXI_ARLENW_WIDTH = $clog2(H_VISIBLE);
  logic                        beat_read_done;
  logic                        beat_read_done_last;

  logic [  AXI_ADDR_WIDTH-1:0] axi_araddr;
  logic [AXI_ARLENW_WIDTH-1:0] axi_arlenw;
  logic                        axi_arvalid;
  logic                        axi_arready;
  // verilator lint_off UNUSEDSIGNAL
  // Not all bits of rdata are used
  logic [  AXI_DATA_WIDTH-1:0] axi_rdata;
  logic [                 1:0] axi_rresp;
  // verilator lint_on UNUSEDSIGNAL
  logic                        axi_rvalid;
  logic                        axi_rlast;
  logic                        axi_rready;

  //
  // pixel iterator
  //
  localparam X_BITS = $clog2(H_WHOLE_LINE);
  localparam Y_BITS = $clog2(V_WHOLE_FRAME);

  // fb y iter, for read addr calc
  logic [        Y_BITS-1:0] fb_y;
  logic [        Y_BITS-1:0] fb_y_iter_init_val;
  logic [        Y_BITS-1:0] fb_y_iter_max;
  logic                      fb_y_iter_init;
  logic                      fb_y_iter_inc;
  logic                      fb_y_iter_last;

  // pixel x iter, both visible and blanking
  logic [        X_BITS-1:0] pixel_x;
  logic                      pixel_x_vis;

  logic [        X_BITS-1:0] pixel_x_iter_init_val;
  logic [        X_BITS-1:0] pixel_x_iter_max;
  logic                      pixel_x_iter_init;
  logic                      pixel_x_iter_inc;
  logic                      pixel_x_iter_last;

  // pixel y iter, both visible and blanking
  logic [        Y_BITS-1:0] pixel_y;
  logic                      pixel_y_vis;

  logic [        Y_BITS-1:0] pixel_y_iter_init_val;
  logic [        Y_BITS-1:0] pixel_y_iter_max;
  logic                      pixel_y_iter_init;
  logic                      pixel_y_iter_inc;
  logic                      pixel_y_iter_last;


  //
  // registered response to the caller
  //
  logic                      pixel_valid;
  logic                      pixel_visible;
  logic                      pixel_hsync;
  logic                      pixel_vsync;
  logic [AXI_ADDR_WIDTH-1:0] pixel_addr;
  logic [    PIXEL_BITS-1:0] pixel_data;

  //
  // iterators
  //
  assign fb_y_iter_init     = reset || (fb_y_iter_last && beat_read_done_last);
  assign fb_y_iter_init_val = 0;
  assign fb_y_iter_max      = Y_BITS'(V_VISIBLE - 1);
  assign fb_y_iter_inc      = beat_read_done_last;

  iter #(
      .WIDTH(Y_BITS)
  ) fb_y_iter_i (
      .clk     (clk),
      .init    (fb_y_iter_init),
      .init_val(fb_y_iter_init_val),
      .max_val (fb_y_iter_max),
      .inc     (fb_y_iter_inc),
      .val     (fb_y),
      .last    (fb_y_iter_last)
  );

  //
  // fb reader
  //
  axi_stripe_readn #(
      .NUM_S           (NUM_S),
      .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH  (AXI_DATA_WIDTH),
      .AXI_ARLENW_WIDTH(AXI_ARLENW_WIDTH)
  ) axi_stripe_readn_i (
      .axi_clk   (clk),
      .axi_resetn(~reset),

      .in_axi_araddr (axi_araddr),
      .in_axi_arlenw (axi_arlenw),
      .in_axi_arvalid(axi_arvalid),
      .in_axi_arready(axi_arready),
      .in_axi_rdata  (axi_rdata),
      .in_axi_rresp  (axi_rresp),
      .in_axi_rvalid (axi_rvalid),
      .in_axi_rlast  (axi_rlast),
      .in_axi_rready (axi_rready),

      .out_axi_araddr (fb_axi_araddr),
      .out_axi_arvalid(fb_axi_arvalid),
      .out_axi_arready(fb_axi_arready),
      .out_axi_rdata  (fb_axi_rdata),
      .out_axi_rresp  (fb_axi_rresp),
      .out_axi_rvalid (fb_axi_rvalid),
      .out_axi_rready (fb_axi_rready)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      axi_arvalid <= 1'b0;
    end else begin
      if (enable && (!axi_arvalid || axi_arready)) begin
        axi_araddr  <= fb_y * H_VISIBLE;
        axi_arlenw  <= AXI_ARLENW_WIDTH'(H_VISIBLE - 1);
        axi_arvalid <= 1'b1;
      end else begin
        if (axi_arvalid && axi_arready) begin
          axi_arvalid <= 1'b0;
        end
      end
    end
  end

  assign axi_rready = (enable && pixel_x_vis && pixel_y_vis);
  assign beat_read_done = axi_rvalid && axi_rready;
  assign beat_read_done_last = axi_rvalid && axi_rready && axi_rlast;

  //
  // Return pixels to the caller
  //
  assign pixel_x_iter_init = (enable && pixel_x_iter_last) || reset;
  assign pixel_x_iter_init_val = 0;
  assign pixel_x_iter_max = X_BITS'(H_WHOLE_LINE - 1);
  assign pixel_x_iter_inc = (beat_read_done ||
                             (enable && !(pixel_x_vis && pixel_y_vis)));

  assign pixel_x_vis = pixel_x < H_VISIBLE;

  iter #(
      .WIDTH(X_BITS)
  ) pixel_x_iter_i (
      .clk     (clk),
      .init    (pixel_x_iter_init),
      .init_val(pixel_x_iter_init_val),
      .max_val (pixel_x_iter_max),
      .inc     (pixel_x_iter_inc),
      .val     (pixel_x),
      .last    (pixel_x_iter_last)
  );

  assign pixel_y_iter_init = (enable && pixel_y_iter_last &&
                              pixel_x_iter_last) || reset;
  assign pixel_y_iter_init_val = 0;
  assign pixel_y_iter_max = Y_BITS'(V_WHOLE_FRAME - 1);
  assign pixel_y_iter_inc = enable && pixel_x_iter_last;

  assign pixel_y_vis = pixel_y < V_VISIBLE;

  iter #(
      .WIDTH(Y_BITS)
  ) pixel_y_iter_i (
      .clk     (clk),
      .init    (pixel_y_iter_init),
      .init_val(pixel_y_iter_init_val),
      .max_val (pixel_y_iter_max),
      .inc     (pixel_y_iter_inc),
      .val     (pixel_y),
      .last    (pixel_y_iter_last)
  );

  logic hsync_pulse;
  assign hsync_pulse = (pixel_x >= H_SYNC_START && pixel_x < H_SYNC_END);

  logic vsync_pulse;
  assign vsync_pulse = (pixel_y >= V_SYNC_START && pixel_y < V_SYNC_END);

  // prep the pixel data
  always @(posedge clk) begin
    if (reset) begin
      pixel_valid <= 1'b0;
    end else begin
      // even though pixel_addr really should only be used when the pixel is
      // visible, always returning it, even for non-visible pixels, helps
      // debug simulations when pixels are dropped.
      pixel_addr  <= (pixel_y * H_VISIBLE) + AXI_ADDR_WIDTH'(pixel_x);
      pixel_valid <= 1'b0;

      if (pixel_x_vis && pixel_y_vis) begin
        pixel_valid <= 1'b0;

        if (beat_read_done) begin
          pixel_valid   <= 1'b1;
          pixel_visible <= 1'b1;
          pixel_hsync   <= 1'b1;
          pixel_vsync   <= 1'b1;
          pixel_data    <= axi_rdata[PIXEL_BITS-1:0];
        end
      end else begin
        if (enable) begin
          pixel_valid   <= 1'b1;
          pixel_visible <= 1'b0;
          pixel_hsync   <= !hsync_pulse;
          pixel_vsync   <= !vsync_pulse;
          pixel_data    <= '0;
        end
      end
    end
  end

  assign valid   = pixel_valid;
  assign visible = pixel_visible;
  assign hsync   = pixel_hsync;
  assign vsync   = pixel_vsync;
  assign addr    = pixel_addr;
  assign color   = pixel_data;

endmodule

`endif
