`ifndef GFX_CLEAR_V
`define GFX_CLEAR_V

`include "directives.v"

`include "vga_mode.v"

module gfx_clear #(
    parameter FB_WIDTH   = `VGA_MODE_H_VISIBLE,
    parameter FB_HEIGHT  = `VGA_MODE_V_VISIBLE,
    parameter PIXEL_BITS = 12
) (
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  inc,
    output reg  [ FB_X_BITS-1:0] x,
    output reg  [ FB_Y_BITS-1:0] y,
    output reg  [PIXEL_BITS-1:0] color,
    output reg                   valid,
    output reg                   last
);
  // Frame buffer coordinate width calculations
  localparam FB_X_BITS = $clog2(FB_WIDTH);
  localparam FB_Y_BITS = $clog2(FB_HEIGHT);
  localparam COLOR_BITS = PIXEL_BITS / 3;

  localparam MAX_X = FB_WIDTH - 1;
  localparam MAX_Y = FB_HEIGHT - 1;

  always @(*) begin
    last = (x == MAX_X & y == MAX_Y);
  end

  reg [FB_X_BITS-1:0] next_x;
  reg [FB_Y_BITS-1:0] next_y;

  always @(*) begin
    next_x = x;
    next_y = y;

    if (inc) begin
      if (x == MAX_X) begin
        next_x = 0;
        if (y == MAX_Y) begin
          next_y = 0;
        end else begin
          next_y = y + 1;
        end
      end else begin
        next_x = x + 1;
      end
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      x <= 0;
      y <= 0;
    end else begin
      if (!done & inc) begin
        x <= next_x;
        y <= next_y;
      end
    end
  end

  always @(posedge clk) begin
    // doing this in reset helps meet timing. (it meets with 0 outside reset,
    // but not with other colors)
    if (reset) begin
      color <= {PIXEL_BITS{1'b0}};
    end
  end

  reg done;
  always @(posedge clk) begin
    if (reset) begin
      done <= 1'b0;
    end else begin
      if (!done) begin
        done <= last;
      end
    end
  end

  always @(posedge clk) begin
    valid <= !done;
  end

endmodule

`endif
