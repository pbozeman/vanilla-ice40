`ifndef VGA_FB_PIXEL_STREAM_V
`define VGA_FB_PIXEL_STREAM_V

// This runs in the axi clock domain and is expected to be bridged
// via a fifo to a module pushing bits to the vga.

`include "directives.v"

// `include "counter.v"
`include "vga_sync.v"

// verilator lint_off UNUSEDSIGNAL
// verilator lint_off UNDRIVEN
// verilator lint_off UNUSEDPARAM
module vga_fb_pixel_stream #(
    parameter PIXEL_BITS = 12,

    parameter H_VISIBLE     = 640,
    parameter H_FRONT_PORCH = 16,
    parameter H_SYNC_PULSE  = 96,
    parameter H_BACK_PORCH  = 48,
    parameter H_WHOLE_LINE  = 800,

    parameter V_VISIBLE     = 480,
    parameter V_FRONT_PORCH = 10,
    parameter V_SYNC_PULSE  = 2,
    parameter V_BACK_PORCH  = 33,
    parameter V_WHOLE_FRAME = 525,

    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input wire clk,
    input wire reset,

    // stream signals
    input  wire enable,
    output wire valid,

    // sync signals
    output wire vsync,
    output wire hsync,

    // color
    output wire [COLOR_BITS-1:0] red,
    output wire [COLOR_BITS-1:0] grn,
    output wire [COLOR_BITS-1:0] blu,

    output wire [AXI_ADDR_WIDTH-1:0] xxx_addr,

    //
    // The AXI interface backing the frame buffer.
    // This module is the master.
    //
    output reg  [AXI_ADDR_WIDTH-1:0] sram_axi_araddr,
    output reg                       sram_axi_arvalid,
    input  wire                      sram_axi_arready,
    input  wire [AXI_DATA_WIDTH-1:0] sram_axi_rdata,
    output reg                       sram_axi_rready,
    input  wire [               1:0] sram_axi_rresp,
    input  wire                      sram_axi_rvalid
);
  localparam FB_X_BITS = $clog2(H_WHOLE_LINE);
  localparam FB_Y_BITS = $clog2(V_WHOLE_FRAME);

  localparam MAX_PIXEL_ADDR = H_VISIBLE * V_VISIBLE - 1;
  localparam COLOR_BITS = PIXEL_BITS / 3;

  wire fb_pixel_visible;
  wire fb_pixel_hsync;
  wire fb_pixel_vsync;
  wire [FB_X_BITS-1:0] fb_pixel_column;
  wire [FB_Y_BITS-1:0] fb_pixel_row;

  // In this context, fb_pixel_visible is the previous value. Keep generating
  // pixels in the non-visible area as long as we are enabled.
  wire fb_pixel_inc = (read_start | (!fb_pixel_visible & enable));

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

  reg  [AXI_ADDR_WIDTH-1:0] fb_pixel_addr;
  wire [AXI_ADDR_WIDTH-1:0] fb_pixel_addr_calc;

  // This was measured to be faster than a counter. When registering the
  // final outputs just before sending them (to pipeline the addr calc),
  // multiply was achieving 145Mhz maxf while the counter was 112 maxf.
  // (After adding more logic to this module, maxf dropped to 130ish, but adding
  // more pipelining can get it back, which isn't really worth doing since
  // we are meeting timing by a wide margin.
  //
  // One sram reads were added, the overall maxf dropped to around 115 mhz.
  // I think the limiting factor is the sram controller. So, it's important
  // to have a fresh pipeline point just before calling into it, as we are
  // doing with the _p1 signals.
  assign fb_pixel_addr_calc = (H_VISIBLE * fb_pixel_row) + fb_pixel_column;

  // Pipelined versions of the signals prior to kicking off the read
  reg                      enable_p1;
  reg                      fb_pixel_visible_p1;
  reg                      fb_pixel_hsync_p1;
  reg                      fb_pixel_vsync_p1;
  reg [     FB_X_BITS-1:0] fb_pixel_column_p1;
  reg [     FB_Y_BITS-1:0] fb_pixel_row_p1;
  reg [AXI_ADDR_WIDTH-1:0] fb_pixel_addr_p1;

  always @(posedge clk) begin
    if (reset) begin
      enable_p1 <= 1'b0;
    end else begin
      enable_p1 <= enable;
    end
  end

  always @(posedge clk) begin
    fb_pixel_visible_p1 <= fb_pixel_visible;
    fb_pixel_hsync_p1   <= fb_pixel_hsync;
    fb_pixel_vsync_p1   <= fb_pixel_vsync;
    fb_pixel_column_p1  <= fb_pixel_column;
    fb_pixel_row_p1     <= fb_pixel_row;
    fb_pixel_addr_p1    <= fb_pixel_addr_calc;
  end

  //
  // State definitions
  //
  localparam IDLE = 1'b0;
  localparam READING = 1'b1;

  reg  state;
  reg  next_state;

  // Read flags for reading from frame buffer
  reg  read_start;
  wire read_accepted = sram_axi_arready & sram_axi_arvalid;
  wire read_done = sram_axi_rready & sram_axi_rvalid;

  // state machine
  always @(*) begin
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

  always @(posedge clk) begin
    if (read_start) begin
      sram_axi_araddr <= fb_pixel_addr_p1;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      sram_axi_rready <= 1'b1;
    end
  end

  assign hsync    = fb_pixel_hsync_p1;
  assign vsync    = fb_pixel_vsync_p1;
  assign xxx_addr = fb_pixel_addr_p1;

endmodule
// verilator lint_on UNUSEDSIGNAL
// verilator lint_on UNDRIVEN
// verilator lint_on UNUSEDPARAM

`endif
