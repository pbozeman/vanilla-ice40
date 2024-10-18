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

    // SRAM AXI-Lite Read Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0] axi_araddr,
    output reg                       axi_arvalid,
    input  wire                      axi_arready,

    // SRAM AXI-Lite Read Data Channel
    input  wire [AXI_DATA_WIDTH-1:0] axi_rdata,
    // verilator lint_off UNUSEDSIGNAL
    input  wire [               1:0] axi_rresp,
    // verilator lint_on UNUSEDSIGNAL
    input  wire                      axi_rvalid,
    output reg                       axi_rready,

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
  reg started = 0;


  // State definitions
  //
  // TODO: we really should have a blanking state so that we are
  // not reading memory during the blanking period. We end up
  // just ignoring the results, but it's potentially confusing
  // and prevents us from doing anything with memory during
  // the blanking period.
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] READ = 2'b01;
  localparam [1:0] READ_WAIT = 2'b10;

  reg  [               1:0] state;
  reg  [               1:0] next_state;

  // Read controls
  wire [AXI_ADDR_WIDTH-1:0] pixel_addr;

  //
  // started
  //
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      started <= 0;
    end else begin
      if (enable & !started) begin
        started <= 1;
      end
    end
  end

  //
  // read row/column
  //
  reg [9:0] read_column;
  reg [9:0] read_row;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      read_column <= 0;
      read_row    <= 0;
    end else begin
      if (read_start) begin
        if (read_column < H_WHOLE_LINE) begin
          read_column <= read_column + 1;
        end else begin
          read_column <= 0;
          if (read_row < V_WHOLE_FRAME) begin
            read_row <= read_row + 1;
          end else begin
            read_row <= 0;
          end
        end
      end
    end
  end

  // We're reading non-visible "pixels" too during the blanking periods,
  // but we don't forward them and it's harmless. Considering
  // complicating the state machine to not read the non-pixels.
  assign pixel_addr = (read_row * H_VISIBLE) + read_column;

  //
  // State machine
  //
  always @(*) begin
    next_state = state;

    case (state)
      IDLE: begin
        if (started & enable) begin
          next_state = READ;
        end
      end

      READ: begin
        next_state = READ_WAIT;
      end

      READ_WAIT: begin
        if (read_accepted) begin
          if (enable) begin
            next_state = READ;
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
  wire read_start;
  assign read_start = (state != READ & next_state == READ);

  wire read_accepted;
  assign read_accepted = axi_arready & axi_arvalid;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      axi_arvalid <= 1'b0;
      axi_rready  <= 1'b0;
    end else begin
      axi_rready <= 1'b1;

      if (read_start) begin
        axi_araddr  <= pixel_addr;
        axi_arvalid <= 1'b1;
      end else begin
        if (read_accepted) begin
          axi_arvalid <= 1'b0;
        end
      end
    end
  end

  //
  // vga pixel position. Note, this lags the column/row
  // used for reading above. While we might happen to know
  // the timing of the sram used, I didn't want to bake that
  // assumption in and have an N clock shift register.
  //
  // I don't have good intuition if this uses less resources than
  // using a fifo to pass the row/column used for the read.
  //
  reg [9:0] vga_column = 0;
  reg [9:0] vga_row = 0;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      vga_column <= 0;
      vga_row    <= 0;
    end else begin
      if (read_done) begin
        if (vga_column < H_WHOLE_LINE) begin
          vga_column <= vga_column + 1;
        end else begin
          vga_column <= 0;
          if (vga_row < V_WHOLE_FRAME) begin
            vga_row <= vga_row + 1;
          end else begin
            vga_row <= 0;
          end
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
  wire vga_visible;
  assign vga_visible = (vga_column < H_VISIBLE && vga_row < V_VISIBLE) ? 1 : 0;

  reg        hsync_r = 0;
  reg        vsync_r = 0;
  reg  [3:0] red_r = 0;
  reg  [3:0] green_r = 0;
  reg  [3:0] blue_r = 0;
  reg        valid_r = 0;

  wire       read_done;
  assign read_done = (axi_rready & axi_rvalid);

  // verilator lint_off UNUSEDSIGNAL
  wire [3:0] unused_axi_rdata = axi_rdata[3:0];
  // verilator lint_on UNUSEDSIGNAL

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
        hsync_r <= (vga_column >= H_SYNC_START && vga_column < H_SYNC_END) ? 0 :
            1;
        vsync_r <= (vga_row >= V_SYNC_START && vga_row < V_SYNC_END) ? 0 : 1;

        red_r <= vga_visible ? axi_rdata[15:12] : 4'b0000;
        green_r <= vga_visible ? axi_rdata[11:8] : 4'b0000;
        blue_r <= vga_visible ? axi_rdata[7:4] : 4'b0000;
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
