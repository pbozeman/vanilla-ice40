`ifndef VGA_SRAM_PIXEL_STREAM_V
`define VGA_SRAM_PIXEL_STREAM_V

// This runs in the axi clock domain and is expected to be bridged
// via a fifo to a module pushing bits to the vga

`include "directives.v"

// defaults to industry standard 640x480@60Hz
// http://www.tinyvga.com/vga-timing/640x480@60Hz
module vga_sram_pixel_stream #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,

    parameter H_VISIBLE     = 640,
    parameter H_FRONT_PORCH = 16,
    parameter H_SYNC_PULSE  = 96,
    // verilator lint_off UNUSEDPARAM
    parameter H_BACK_PORCH  = 48,
    // verilator lint_on UNUSEDPARAM
    parameter H_WHOLE_LINE  = 800,

    parameter V_VISIBLE     = 480,
    parameter V_FRONT_PORCH = 10,
    parameter V_SYNC_PULSE  = 2,
    // verilator lint_off UNUSEDPARAM
    parameter V_BACK_PORCH  = 33,
    // verilator lint_on UNUSEDPARAM
    parameter V_WHOLE_FRAME = 525
) (
    input wire clk,
    input wire reset,
    input wire enable,

    // TODO: enable when this is turned back on
    // verilator lint_off UNUSEDSIGNAL
    //
    // SRAM AXI-Lite Read Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0] axi_araddr,
    output reg                       axi_arvalid,
    input  wire                      axi_arready,

    // SRAM AXI-Lite Read Data Channel
    input  wire [AXI_DATA_WIDTH-1:0] axi_rdata,
    input  wire [               1:0] axi_rresp,
    input  wire                      axi_rvalid,
    output reg                       axi_rready,
    // verilator lint_on UNUSEDSIGNAL

    // VGA signals
    output wire       vsync,
    output wire       hsync,
    output wire [3:0] red,
    output wire [3:0] green,
    output wire [3:0] blue,
    output wire       valid
);
  localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
  localparam H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;

  localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
  localparam V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;

  // Don't start running until we are told to.
  reg       started = 0;

  // Col/row
  reg [9:0] column = 0;
  reg [9:0] row = 0;

  // State definitions
  //
  // TODO: we really should have a blanking state so that we are
  // not reading memory during the blanking period. We end up
  // just ignoring the results, but it's potentially confusing
  // and prevents us from doing anything with memory during
  // the blanking period.
  localparam IDLE = 1'b0;
  localparam READING = 1'b1;

  reg                       state = IDLE;
  reg                       next_state;

  // Read controls
  reg                       read_start;
  wire                      read_done;
  wire [AXI_ADDR_WIDTH-1:0] pixel_addr;

  //
  // started
  //
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      started <= 0;
    end else begin
      if (enable && !started) begin
        started <= 1;
      end
    end
  end

  //
  // row/column
  //
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      column <= 0;
      row    <= 0;
    end else begin
      if (read_start & enable) begin
        if (column < H_WHOLE_LINE) begin
          column <= column + 1;
        end else begin
          column <= 0;
          if (row < V_WHOLE_FRAME) begin
            row <= row + 1;
          end else begin
            row <= 0;
          end
        end
      end
    end
  end

  // We're reading non-visible "pixels" too during the blanking periods,
  // but we don't forward them and it's harmless. Considering
  // complicating the state machine to not read the non-pixels.
  assign pixel_addr = (row * H_VISIBLE) + column;

  //
  // State machine
  //
  // (brought in as boiler plate.. this can probably be removed as this is so
  // simple)
  //
  always @(*) begin
    next_state = state;
    read_start = 1'b0;

    if (!reset) begin
      case (state)
        IDLE: begin
          if (started && enable) begin
            read_start = 1'b1;
            next_state = READING;
          end
        end

        READING: begin
          if (read_done) begin
            if (enable) begin
              read_start = 1'b1;
            end else begin
              next_state = IDLE;
            end
          end
        end
      endcase
    end
  end

  // state registration
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  //
  // AXI Read
  //
  assign read_done = (axi_rready && axi_rvalid);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      axi_arvalid <= 1'b0;
      axi_rready  <= 1'b0;
    end else begin
      // We're always ready for a response
      axi_rready <= 1'b1;

      if (read_start) begin
        axi_araddr  <= pixel_addr;
        axi_arvalid <= 1'b1;
      end else begin
        if (read_done) begin
          axi_arvalid <= 1'b0;
        end
      end
    end
  end


  //
  // Pixel outputs
  //
  // Register them all at the same time so that all the signals
  // are in sync.
  //
  wire visible;
  assign visible = (column < H_VISIBLE && row < V_VISIBLE) ? 1 : 0;

  reg       hsync_r = 0;
  reg       vsync_r = 0;
  reg [3:0] red_r = 0;
  reg [3:0] green_r = 0;
  reg [3:0] blue_r = 0;
  reg       valid_r = 0;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      valid_r <= 1'b0;
      hsync_r <= 1'b0;
      red_r   <= 1'b0;
      green_r <= 1'b0;
      blue_r  <= 1'b0;
      valid_r <= 1'b0;
    end else begin
      valid_r <= 1'b0;

      if (read_done) begin
        hsync_r <= (column >= H_SYNC_START && column < H_SYNC_END) ? 0 : 1;
        vsync_r <= (row >= V_SYNC_START && row < V_SYNC_END) ? 0 : 1;

        red_r   <= visible ? axi_rdata[15:12] : 4'b0000;
        green_r <= visible ? axi_rdata[11:8] : 4'b0000;
        blue_r  <= visible ? axi_rdata[7:4] : 4'b0000;
        valid_r <= 1'b1;
      end
    end
  end

  // vga signal
  assign hsync = hsync_r;
  assign vsync = vsync_r;

  // colors
  assign red   = red_r;
  assign green = green_r;
  assign blue  = blue_r;

  assign valid = valid_r;

endmodule

`endif
