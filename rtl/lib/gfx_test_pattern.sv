`ifndef GFX_TEST_PATTERN_V
`define GFX_TEST_PATTERN_V

`include "directives.sv"

`include "vga_mode.sv"

module gfx_test_pattern #(
    parameter FB_WIDTH   = `VGA_MODE_H_VISIBLE,
    parameter FB_HEIGHT  = `VGA_MODE_V_VISIBLE,
    parameter PIXEL_BITS = 12
) (
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  pready,
    output logic                  pvalid,
    output logic [ FB_X_BITS-1:0] x,
    output logic [ FB_Y_BITS-1:0] y,
    output logic [PIXEL_BITS-1:0] color,
    output logic                  last
);

  // Frame buffer coordinate width calculations
  localparam FB_X_BITS = $clog2(FB_WIDTH);
  localparam FB_Y_BITS = $clog2(FB_HEIGHT);
  localparam COLOR_BITS = PIXEL_BITS / 3;

  localparam MAX_X = FB_WIDTH - 1;
  localparam MAX_Y = FB_HEIGHT - 1;

  always_comb begin
    last = (x == MAX_X & y == MAX_Y);
  end

  logic [FB_X_BITS-1:0] next_x;
  logic [FB_Y_BITS-1:0] next_y;

  logic                 pixel_done;
  assign pixel_done = (pready && pvalid);

  always_comb begin
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
      if (pixel_done) begin
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

  logic [COLOR_BITS-1:0] red;
  logic [COLOR_BITS-1:0] grn;
  logic [COLOR_BITS-1:0] blu;

  localparam color_on = {COLOR_BITS{1'b1}};
  localparam color_off = {COLOR_BITS{1'b0}};

  localparam THIRD_SCREEN = `VGA_MODE_H_VISIBLE / 3;
  localparam RED_END = THIRD_SCREEN;
  localparam GRN_START = RED_END;
  localparam GRN_END = THIRD_SCREEN * 2;
  localparam BLU_START = GRN_END;

  assign red = next_x < RED_END ? color_on : color_off;
  assign grn = next_x >= GRN_START && next_x < GRN_END ? color_on : color_off;
  assign blu = next_x >= BLU_START ? color_on : color_off;

  always_ff @(posedge clk) begin
    if (reset) begin
      x <= 0;
      y <= 0;
    end else begin
      if (!done & pixel_done) begin
        x <= next_x;
        y <= next_y;
      end
    end
  end

  always_ff @(posedge clk) begin
    color <= {red, grn, blu};
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      pvalid <= 0;
    end else begin
      if (!done) begin
        pvalid <= 1'b1;
      end

      // TODO: this is not going as fast as we could
      if (pvalid && pready) begin
        pvalid <= 1'b0;
      end
    end
  end

  logic done;
  always_ff @(posedge clk) begin
    if (reset) begin
      done <= 1'b0;
    end else begin
      if (!done) begin
        done <= last;
      end
    end
  end

endmodule

`endif
