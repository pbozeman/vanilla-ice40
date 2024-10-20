`ifndef VGA_SRAM_PIXEL_STREAM_V
`define VGA_SRAM_PIXEL_STREAM_V

// This runs in the axi clock domain and is expected to be bridged
// via a fifo to a module pushing bits to the vga.

`include "directives.v"

`include "counter.v"
`include "delay.v"
`include "fifo.v"
`include "vga_sync.v"

// defaults to industry standard 640x480@60Hz
// http://www.tinyvga.com/vga-timing/640x480@60Hz
module vga_sram_pixel_stream #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,

    parameter H_VISIBLE     = 640,
    parameter H_FRONT_PORCH = 16,
    parameter H_SYNC_PULSE  = 96,
    parameter H_BACK_PORCH  = 48,
    parameter H_WHOLE_LINE  = 800,

    parameter V_VISIBLE     = 480,
    parameter V_FRONT_PORCH = 10,
    parameter V_SYNC_PULSE  = 2,
    parameter V_BACK_PORCH  = 33,
    parameter V_WHOLE_FRAME = 525
) (
    input wire clk,
    input wire reset,
    input wire enable,

    // SRAM AXI-Lite Read Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0] axi_araddr,
    output reg                       axi_arvalid,
    input  wire                      axi_arready,

    // SRAM AXI-Lite Read Data Channel
    input  wire [AXI_DATA_WIDTH-1:0] axi_rdata,
    // verilator lint_off UNUSEDSIGNAL
    input  wire [               1:0] axi_rresp,
    input  wire                      axi_rvalid,
    // verilator lint_on UNUSEDSIGNAL
    output reg                       axi_rready,

    // VGA signals
    output wire       vsync,
    output wire       hsync,
    output wire [3:0] red,
    output wire [3:0] green,
    output wire [3:0] blue,
    output wire       valid

);
  localparam MAX_PIXEL_ADDR = H_VISIBLE * V_VISIBLE;

  //
  // Enable comes in on a wire and is potentially
  // expensive. Pipeline it.
  //
  reg enabled = 1'b0;
  always @(posedge clk) begin
    if (reset) begin
      enabled <= 1'b0;
    end else begin
      enabled <= enable;
    end
  end

  wire fb_pixel_visible;
  wire fb_pixel_hsync;
  wire fb_pixel_vsync;
  wire [AXI_ADDR_WIDTH-1:0] fb_pixel_addr;

  // verilator lint_off UNUSEDSIGNAL
  wire [9:0] fb_pixel_column;
  wire [9:0] fb_pixel_row;
  // verilator lint_on UNUSEDSIGNAL

  // In this context, fb_pixel_visible is the previous value.
  // Keep generating pixels in the non-visible area as long
  // as we are enabled. Otherwise, we need to wait for our
  // reads to get registered before we clobber them.
  wire fb_pixel_inc = (read_start | (!fb_pixel_visible & enabled));

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

  // we only increment the pixel fb addr for actual visible
  // pixels that we do reads on
  counter #(
      .MAX_VALUE(MAX_PIXEL_ADDR),
      .WIDTH    (AXI_ADDR_WIDTH)
  ) fb_pixel_counter (
      .clk   (clk),
      .reset (reset),
      .enable(read_start),
      .count (fb_pixel_addr)
  );

  //
  // Read flags for reading from frame buffer
  //
  reg  read_start;
  wire read_accepted = axi_arready & axi_arvalid;
  wire read_done = axi_rready & axi_rvalid;

  //
  // State definitions
  //
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] READ = 2'b01;
  localparam [1:0] READ_WAIT = 2'b10;

  reg [1:0] state;
  reg [1:0] next_state;

  //
  // State machine
  //
  always @(*) begin
    next_state = state;
    read_start = 1'b0;

    case (state)
      IDLE: begin
        if (enabled) begin
          // We just stay in the idle state during the blanking
          // periods.
          if (fb_pixel_visible) begin
            next_state = READ;
            read_start = 1'b1;
          end
        end
      end

      READ: begin
        next_state = READ_WAIT;
      end

      READ_WAIT: begin
        if (read_accepted) begin
          if (enabled & fb_pixel_visible) begin
            next_state = READ;
            read_start = 1'b1;
          end else begin
            next_state = IDLE;
          end
        end
      end

      default: begin
      end

    endcase
  end

  // state registration
  always @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  //
  // AXI Read
  //
  always @(posedge clk) begin
    if (read_start) begin
      axi_araddr <= fb_pixel_addr;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      axi_rready <= 1'b1;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      axi_arvalid <= 1'b0;
    end else begin
      if (read_start) begin
        axi_arvalid <= 1'b1;
      end else begin
        if (read_accepted) begin
          axi_arvalid <= 1'b0;
        end
      end
    end
  end

  //
  // Send the metadata we computed about the pixel through
  // a fifo to be matched with it's pixel value from the
  // frame buffer.
  //
  // One alternative to this would be a shift register,
  // but that requires us to know the pipeline size
  // of the axi stream.
  //
  localparam PIXEL_CONTEXT_WIDTH = 3;
  wire [PIXEL_CONTEXT_WIDTH-1:0] pixel_context_send;
  wire [PIXEL_CONTEXT_WIDTH-1:0] pixel_context_recv;

  // marshal the pixel metadata for the fifo
  assign pixel_context_send = {
    fb_pixel_visible, fb_pixel_vsync, fb_pixel_hsync
  };

  // the receiver signals
  wire pixel_visible;
  wire pixel_vsync;
  wire pixel_hsync;
  wire pixel_valid;

  wire fifo_empty;
  // verilator lint_off UNUSEDSIGNAL
  wire fifo_full;
  // verilator lint_on UNUSEDSIGNAL

  wire pixel_inc = !fifo_empty & (read_done | !fb_pixel_visible);

  fifo #(
      .DATA_WIDTH(PIXEL_CONTEXT_WIDTH)
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

  wire pixel_inc_p1;
  delay u_pixel_p1 (
      .clk(clk),
      .in (pixel_inc),
      .out(pixel_inc_p1)
  );

  // unmarshal the pixel metadata to send to the caller
  assign pixel_visible = pixel_context_recv[2];
  assign pixel_vsync   = pixel_context_recv[1];
  assign pixel_hsync   = pixel_context_recv[0];
  assign pixel_valid   = pixel_inc_p1;

  reg                      pixel_hsync_r;
  reg                      pixel_vsync_r;
  reg                      pixel_visible_r;
  reg [AXI_DATA_WIDTH-1:0] pixel_data_r;
  reg                      pixel_valid_r;

  // The pixel data from the fifo won't be valid for awhile, so set
  // the important bits. hsync/vsync so the monitor won't try to interpret
  // data, and so that high

  always @(posedge clk) begin
    if (reset) begin
      pixel_hsync_r   <= 1'b1;
      pixel_vsync_r   <= 1'b1;
      pixel_visible_r <= 1'b1;
    end else begin
      if (pixel_valid) begin
        pixel_hsync_r   <= pixel_hsync;
        pixel_vsync_r   <= pixel_vsync;
        pixel_visible_r <= pixel_visible;
      end
    end
  end

  always @(posedge clk) begin
    pixel_valid_r <= pixel_inc;

    if (read_done) begin
      pixel_data_r <= axi_rdata;
    end
  end

  //
  // vga signal to caller
  //
  assign hsync = pixel_hsync_r;
  assign vsync = pixel_vsync_r;

  //
  // colors to caller
  //
  assign red   = pixel_visible_r ? pixel_data_r[15:12] : 4'b0000;
  assign green = pixel_visible_r ? pixel_data_r[11:8] : 4'b0000;
  assign blue  = pixel_visible_r ? pixel_data_r[7:4] : 4'b0000;
  assign valid = pixel_valid_r;

  // verilator lint_off UNUSEDSIGNAL
  wire [3:0] unused_rdata = pixel_data_r[3:0];
  // verilator lint_on UNUSEDSIGNAL

endmodule

`endif
