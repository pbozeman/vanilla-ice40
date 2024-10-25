`ifndef GFX_TEST_PATTERN_V
`define GFX_TEST_PATTERN_V

`include "directives.v"

module gfx_test_pattern #(
    parameter FB_WIDTH   = 640,
    parameter FB_HEIGHT  = 480,
    parameter PIXEL_BITS = 12
) (
    input  wire                 clk,
    input  wire                 reset,
    input  wire                 enable,
    output reg  [FB_X_BITS-1:0] x,
    output reg  [FB_Y_BITS-1:0] y,
    output reg                  valid,
    output reg                  last
);

  // Frame buffer coordinate width calculations
  localparam FB_X_BITS = $clog2(FB_WIDTH);
  localparam FB_Y_BITS = $clog2(FB_HEIGHT);

  localparam MAX_X = FB_WIDTH - 1;
  localparam MAX_Y = FB_HEIGHT - 1;

  always @(*) begin
    last = (x == MAX_X & y == MAX_Y);
  end

  always @(posedge clk) begin
    if (reset) begin
      x     <= 0;
      y     <= 0;
      valid <= 0;
      last  <= 0;
    end else begin
      if (enable) begin
        valid <= 1;

        if (x == MAX_X) begin
          x <= 0;
          if (y == MAX_Y) begin
            y <= 0;
          end else begin
            y <= y + 1;
          end
        end else begin
          x <= x + 1;
        end
      end
    end
  end

endmodule

`endif
