`ifndef GFX_CLEAR_V
`define GFX_CLEAR_V

`include "directives.sv"

`include "vga_mode.sv"

module gfx_clear #(
    parameter FB_WIDTH   = 640,
    parameter FB_HEIGHT  = 480,
    parameter PIXEL_BITS = 12,

    // Frame buffer coordinate width calculations
    localparam FB_X_BITS = $clog2(FB_WIDTH),
    localparam FB_Y_BITS = $clog2(FB_HEIGHT)
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
  localparam MAX_X = FB_X_BITS'(FB_WIDTH - 1);
  localparam MAX_Y = FB_Y_BITS'(FB_HEIGHT - 1);

  logic [FB_X_BITS-1:0] next_x;
  logic [FB_Y_BITS-1:0] next_y;

  logic                 pixel_done;
  assign pixel_done = (pready && pvalid);

  always_comb begin
    next_x = x;
    next_y = y;

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

  always_ff @(posedge clk) begin
    if (reset) begin
      x <= 0;
    end else begin
      if (!done & pixel_done) begin
        x <= next_x;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      y <= 0;
    end else begin
      if (!done & pixel_done) begin
        y <= next_y;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      last <= 1'b0;
    end else begin
      last <= (x == MAX_X && y == MAX_Y);
    end
  end

  always_ff @(posedge clk) begin
    // doing this in reset helps meet timing. (it meets with 0 outside reset,
    // but not with other colors)
    if (reset) begin
      color <= {PIXEL_BITS{1'b0}};
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      pvalid <= 0;
    end else begin
      if (!done_p1) begin
        pvalid <= 1'b1;
      end

      // TODO: this is not going as fast as we could
      if (pvalid && pready) begin
        pvalid <= 1'b0;
      end
    end
  end

  // TODO: this seems like a mess, come back and clean this up
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

  logic done_p1;
  always_ff @(posedge clk) begin
    if (reset) begin
      done_p1 <= 1'b0;
    end else begin
      done_p1 <= done;
    end
  end

endmodule

`endif
