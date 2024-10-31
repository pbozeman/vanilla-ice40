`ifndef GFX_TEST_PATTERN_V
`define GFX_TEST_PATTERN_V

`include "directives.v"

module gfx_test_pattern #(
    parameter FB_WIDTH   = 640,
    parameter FB_HEIGHT  = 480,
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

    if (reset) begin
      // This reset block is to reset the color. I tried doing it in the
      // sync block, but that didn't pass timing. This is a work around,
      // although potentially it just nudges nextpnr into a different layout.
      // It seems silly to do this here.
      next_x = 0;
      next_y = 0;
    end else begin
      // if the inc check gets removed, move the color calc
      // into the non-comb block
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
  end

  wire [COLOR_BITS-1:0] red;
  wire [COLOR_BITS-1:0] grn;
  wire [COLOR_BITS-1:0] blu;

  localparam color_on = {COLOR_BITS{1'b1}};
  localparam color_off = {COLOR_BITS{1'b0}};

  assign red = next_x < 213 ? color_on : color_off;
  assign grn = next_x >= 213 && next_x < 426 ? color_on : color_off;
  assign blu = next_x >= 426 ? color_on : color_off;

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
    color <= {red, grn, blu};
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
    if (reset) begin
      valid <= 1'b1;
    end else begin
      valid <= !done;
    end
  end

endmodule

`endif
