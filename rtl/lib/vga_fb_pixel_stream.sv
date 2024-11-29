`ifndef VGA_FB_PIXEL_STREAM_V
`define VGA_FB_PIXEL_STREAM_V

// This runs in the axi clock domain and is expected to be bridged
// via a fifo to a module pushing bits to the vga.

`include "directives.sv"

`include "sync_fifo.sv"
`include "vga_mode.sv"
`include "vga_sync.sv"

module vga_fb_pixel_stream #(
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

    localparam FB_X_BITS = $clog2(H_WHOLE_LINE),
    localparam FB_Y_BITS = $clog2(V_WHOLE_FRAME)
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

    // pixel addr in the fb, this let's a caller get a pixel for display,
    // but also modify it in the frame buffer after. While it might be
    // logically better to return x/y, this prevents the need for a
    // redundant multiply later.
    output logic [AXI_ADDR_WIDTH-1:0] addr,

    //
    // The AXI interface backing the frame buffer.
    // This module is the master.
    //
    output logic [AXI_ADDR_WIDTH-1:0] sram_axi_araddr,
    output logic                      sram_axi_arvalid,
    input  logic                      sram_axi_arready,
    input  logic [AXI_DATA_WIDTH-1:0] sram_axi_rdata,
    output logic                      sram_axi_rready,
    // verilator lint_off UNUSEDSIGNAL
    input  logic [               1:0] sram_axi_rresp,
    // verilator lint_on UNUSEDSIGNAL
    input  logic                      sram_axi_rvalid
);
  logic                 fb_pixel_visible;
  logic                 fb_pixel_hsync;
  logic                 fb_pixel_vsync;
  logic [FB_X_BITS-1:0] fb_pixel_column;
  logic [FB_Y_BITS-1:0] fb_pixel_row;

  // In this context, fb_pixel_visible is the previous value. Keep generating
  // pixels in the non-visible area as long as we are enabled.
  //
  // TODO: fifo_w_almost_full is used here and in enable_p1, which
  // is kinda hacky. Clean up the next pixel signal and enable_p1.
  logic                 fb_pixel_inc;
  assign fb_pixel_inc = (!fifo_w_almost_full &&
                         (read_start || (!fb_pixel_visible && enable)));

  vga_sync #(
      .H_VISIBLE    (H_VISIBLE),
      .H_FRONT_PORCH(H_FRONT_PORCH),
      .H_SYNC_PULSE (H_SYNC_PULSE),
      .H_BACK_PORCH (H_BACK_PORCH),
      .H_WHOLE_LINE (H_WHOLE_LINE),
      .V_VISIBLE    (V_VISIBLE),
      .V_FRONT_PORCH(V_FRONT_PORCH),
      .V_SYNC_PULSE (V_SYNC_PULSE),
      .V_BACK_PORCH (V_BACK_PORCH),
      .V_WHOLE_FRAME(V_WHOLE_FRAME)
  ) sync (
      .clk    (clk),
      .reset  (reset),
      .enable (fb_pixel_inc),
      .visible(fb_pixel_visible),
      .hsync  (fb_pixel_hsync),
      .vsync  (fb_pixel_vsync),
      .column (fb_pixel_column),
      .row    (fb_pixel_row)
  );

  logic [AXI_ADDR_WIDTH-1:0] fb_pixel_addr_calc;
  assign fb_pixel_addr_calc = (H_VISIBLE * fb_pixel_row) + fb_pixel_column;

  // Pipelined versions of the signals prior to kicking off the read.
  // This is to pipeline the mult/add of the addr.
  logic                      enable_p1;
  logic                      fb_pixel_visible_p1;
  logic [AXI_ADDR_WIDTH-1:0] fb_pixel_addr_p1;
  logic                      fb_pixel_hsync_p1;
  logic                      fb_pixel_vsync_p1;
  logic                      fb_pixel_inc_p1;


  always_ff @(posedge clk) begin
    if (reset) begin
      enable_p1 <= 1'b0;
    end else begin
      enable_p1 <= (enable && !fifo_w_almost_full);
    end
  end

  always_ff @(posedge clk) begin
    fb_pixel_inc_p1     <= fb_pixel_inc;
    fb_pixel_addr_p1    <= fb_pixel_addr_calc;
    fb_pixel_visible_p1 <= fb_pixel_visible;
    fb_pixel_hsync_p1   <= fb_pixel_hsync;
    fb_pixel_vsync_p1   <= fb_pixel_vsync;
  end

  //
  // State definitions
  //
  localparam IDLE = 1'b0;
  localparam READING = 1'b1;

  logic state;
  logic next_state;

  // Read flags for reading from frame buffer
  logic read_start;
  logic read_accepted;
  logic read_done;

  assign read_accepted = sram_axi_arready & sram_axi_arvalid;
  assign read_done     = sram_axi_rready & sram_axi_rvalid;

  // state machine
  always_comb begin
    next_state = state;
    read_start = 1'b0;

    case (state)
      IDLE: begin
        if (enable_p1) begin
          // We just stay in the idle state during the blanking periods.
          if (fb_pixel_visible_p1) begin
            next_state = READING;
            read_start = 1'b1;
          end
        end
      end

      READING: begin
        if (read_accepted) begin
          if (enable_p1 & fb_pixel_visible_p1) begin
            next_state = READING;
            read_start = 1'b1;
          end else begin
            next_state = IDLE;
          end
        end
      end
    endcase
  end

  // state registration
  always_ff @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  //
  // AXI Read
  //
  always_ff @(posedge clk) begin
    if (reset) begin
      sram_axi_arvalid <= 1'b0;
    end else begin
      if (read_start) begin
        sram_axi_arvalid <= 1'b1;
      end else begin
        if (read_accepted) begin
          sram_axi_arvalid <= 1'b0;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (read_start) begin
      sram_axi_araddr <= fb_pixel_addr_p1;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      sram_axi_rready <= 1'b1;
    end
  end

  // Send the metadata we computed about the pixel through a fifo to be
  // matched with it's pixel value from the frame buffer.
  localparam PIXEL_CONTEXT_WIDTH = 3 + AXI_ADDR_WIDTH;

  logic [PIXEL_CONTEXT_WIDTH-1:0] fifo_w_data;
  logic                           fifo_w_inc;

  logic [PIXEL_CONTEXT_WIDTH-1:0] fifo_r_data;
  logic                           fifo_r_inc;

  logic                           fifo_r_empty;
  // verilator lint_off UNUSEDSIGNAL
  logic                           fifo_w_full;
  // verilator lint_on UNUSEDSIGNAL
  logic                           fifo_w_almost_full;

  assign fifo_w_data = {
    fb_pixel_visible_p1, fb_pixel_vsync_p1, fb_pixel_hsync_p1, fb_pixel_addr_p1
  };

  assign fifo_w_inc = fb_pixel_inc_p1;
  assign fifo_r_inc = read_done || (!fifo_pixel_visible && !fifo_r_empty);

  // This is very brittle. If this queue becomes longer than the sram
  // read latency, read_done can fire before our pixel metadata has made
  // it through the queue.
  sync_fifo #(
      .DATA_WIDTH     (PIXEL_CONTEXT_WIDTH),
      .ADDR_SIZE      (3),
      .ALMOST_FULL_BUF(2)
  ) fb_fifo (
      .clk          (clk),
      .rst_n        (~reset),
      .w_inc        (fifo_w_inc),
      .w_data       (fifo_w_data),
      .w_full       (fifo_w_full),
      .w_almost_full(fifo_w_almost_full),
      .r_inc        (fifo_r_inc),
      .r_data       (fifo_r_data),
      .r_empty      (fifo_r_empty)
  );

  // unmarshal the pixel metadata from the fifo
  logic                      fifo_pixel_visible;
  logic                      fifo_pixel_vsync;
  logic                      fifo_pixel_hsync;
  logic [AXI_ADDR_WIDTH-1:0] fifo_pixel_addr;

  assign {fifo_pixel_visible, fifo_pixel_vsync, fifo_pixel_hsync,
          fifo_pixel_addr} = fifo_r_data;

  // registered response to the caller
  logic                      pixel_valid;
  logic                      pixel_visible;
  logic                      pixel_hsync;
  logic                      pixel_vsync;
  logic [AXI_ADDR_WIDTH-1:0] pixel_addr;
  logic [AXI_DATA_WIDTH-1:0] pixel_data;

  always @(posedge clk) begin
    pixel_valid <= 1'b0;

    if (!fifo_r_empty) begin
      pixel_visible <= fifo_pixel_visible;
      pixel_hsync   <= fifo_pixel_hsync;
      pixel_vsync   <= fifo_pixel_vsync;
      pixel_addr    <= fifo_pixel_addr;

      if (!fifo_pixel_visible) begin
        pixel_valid <= 1'b1;
      end else begin
        if (read_done) begin
          pixel_valid <= 1'b1;
          pixel_data  <= sram_axi_rdata;
        end
      end
    end
  end

  // the data to use when the pixel is not visible
  logic [AXI_DATA_WIDTH:0] blank_pixel = 0;

  assign hsync = pixel_hsync;
  assign vsync = pixel_vsync;
  assign valid = pixel_valid;
  assign color = pixel_visible ? pixel_data : blank_pixel;
  assign addr  = pixel_addr;

endmodule

`endif
