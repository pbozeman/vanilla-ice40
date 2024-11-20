`ifndef VGA_FB_PIXEL_STREAM_V
`define VGA_FB_PIXEL_STREAM_V

// This runs in the axi clock domain and is expected to be bridged
// via a fifo to a module pushing bits to the vga.

`include "directives.sv"

`include "fifo.sv"
`include "vga_mode.sv"
`include "vga_sync.sv"

module vga_fb_pixel_stream #(
    parameter PIXEL_BITS = 12,
    parameter META_BITS  = 4,

    parameter H_VISIBLE     = `VGA_MODE_H_VISIBLE,
    parameter H_FRONT_PORCH = `VGA_MODE_H_FRONT_PORCH,
    parameter H_SYNC_PULSE  = `VGA_MODE_H_SYNC_PULSE,
    parameter H_BACK_PORCH  = `VGA_MODE_H_BACK_PORCH,
    parameter H_WHOLE_LINE  = `VGA_MODE_H_WHOLE_LINE,

    parameter V_VISIBLE     = `VGA_MODE_V_VISIBLE,
    parameter V_FRONT_PORCH = `VGA_MODE_V_FRONT_PORCH,
    parameter V_SYNC_PULSE  = `VGA_MODE_V_SYNC_PULSE,
    parameter V_BACK_PORCH  = `VGA_MODE_V_BACK_PORCH,
    parameter V_WHOLE_FRAME = `VGA_MODE_V_WHOLE_FRAME,

    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,

    localparam FB_X_BITS  = $clog2(H_WHOLE_LINE),
    localparam FB_Y_BITS  = $clog2(V_WHOLE_FRAME),
    localparam COLOR_BITS = PIXEL_BITS / 3
) (
    input logic clk,
    input logic reset,

    // stream signals
    input  logic enable,
    output logic valid,

    // sync signals
    output logic vsync,
    output logic hsync,

    // color
    output logic [COLOR_BITS-1:0] red,
    output logic [COLOR_BITS-1:0] grn,
    output logic [COLOR_BITS-1:0] blu,
    output logic [ META_BITS-1:0] meta,

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
  logic                 fb_pixel_inc;
  assign fb_pixel_inc = (read_start | (!fb_pixel_visible & enable));

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

  // Pipelined versions of the signals prior to kicking off the read
  logic                      enable_p1;
  logic                      fb_pixel_visible_p1;
  logic                      fb_pixel_hsync_p1;
  logic                      fb_pixel_vsync_p1;
  logic [AXI_ADDR_WIDTH-1:0] fb_pixel_addr_p1;

  always_ff @(posedge clk) begin
    if (reset) begin
      enable_p1 <= 1'b0;
    end else begin
      enable_p1 <= enable;
    end
  end

  always_ff @(posedge clk) begin
    fb_pixel_visible_p1 <= fb_pixel_visible;
    fb_pixel_hsync_p1   <= fb_pixel_hsync;
    fb_pixel_vsync_p1   <= fb_pixel_vsync;
    fb_pixel_addr_p1    <= fb_pixel_addr_calc;
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
  //
  // An alternative to this would be a shift register, but that requires
  // us to know the pipeline size of the axi stream.
  localparam PIXEL_CONTEXT_WIDTH = 3;
  logic [PIXEL_CONTEXT_WIDTH-1:0] pixel_context_send;
  logic [PIXEL_CONTEXT_WIDTH-1:0] pixel_context_recv;

  // marshal the pixel metadata for the fifo
  assign pixel_context_send = {
    fb_pixel_visible, fb_pixel_vsync_p1, fb_pixel_hsync_p1
  };

  logic fifo_empty;
  // verilator lint_off UNUSEDSIGNAL
  logic fifo_full;
  // verilator lint_on UNUSEDSIGNAL

  logic pixel_inc;
  assign pixel_inc = !fifo_empty & (read_done | !fb_pixel_visible_p1);

  fifo #(
      .DATA_WIDTH(PIXEL_CONTEXT_WIDTH),
      .DEPTH     (4)
  ) fb_fifo (
      .clk       (clk),
      .reset     (reset),
      .write_en  (fb_pixel_inc),
      .read_en   (pixel_inc),
      .write_data(pixel_context_send),
      .read_data (pixel_context_recv),
      .empty     (fifo_empty),
      .full      (fifo_full)
  );

  // Delay pixel_inc by 1 because pixel_context_recv comes
  // 1 clock after the inc. Otherwise, we interpret one
  // clock early, which is especially bad at the start (and the end).
  //
  // TODO: the sync fifo interface should be better and operate more
  // like the aysnc fifo does in that the data is valid, if not empty,
  // and inc takes you to the next one.

  logic pixel_inc_p1;
  always_ff @(posedge clk) begin
    if (reset) begin
      pixel_inc_p1 <= 1'b0;
    end else begin
      pixel_inc_p1 <= pixel_inc;
    end
  end

  // unmarshal the pixel metadata to send to the caller
  logic fifo_pixel_visible;
  logic fifo_pixel_vsync;
  logic fifo_pixel_hsync;
  logic fifo_pixel_valid;

  assign fifo_pixel_visible = pixel_context_recv[2];
  assign fifo_pixel_vsync   = pixel_context_recv[1];
  assign fifo_pixel_hsync   = pixel_context_recv[0];

  assign fifo_pixel_valid   = pixel_inc_p1;

  logic                      pixel_visible;
  logic                      pixel_hsync;
  logic                      pixel_vsync;
  logic [AXI_DATA_WIDTH-1:0] pixel_data;
  logic                      pixel_valid;

  // The pixel data from the fifo won't be valid for awhile, so set
  // the important bits. hsync/vsync so the monitor won't try to interpret
  // data.
  always_ff @(posedge clk) begin
    if (reset) begin
      pixel_hsync <= 1'b1;
      pixel_vsync <= 1'b1;
    end else begin
      if (fifo_pixel_valid) begin
        pixel_visible <= fifo_pixel_visible;
        pixel_hsync   <= fifo_pixel_hsync;
        pixel_vsync   <= fifo_pixel_vsync;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      pixel_data  <= 0;
      pixel_valid <= 0;
    end else begin
      pixel_valid <= pixel_inc;

      if (read_done) begin
        pixel_data <= sram_axi_rdata;
      end
    end
  end

  // the data to use when the pixel is not visible
  logic [AXI_DATA_WIDTH:0] blank_pixel = 0;

  assign hsync                 = pixel_hsync;
  assign vsync                 = pixel_vsync;
  assign valid                 = pixel_valid;
  assign {red, grn, blu, meta} = pixel_visible ? pixel_data : blank_pixel;

endmodule

`endif
