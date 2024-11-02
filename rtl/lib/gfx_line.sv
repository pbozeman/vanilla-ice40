`ifndef GFX_LINE_V
`define GFX_LINE_V

`include "directives.sv"

`include "vga_mode.sv"

module gfx_line #(
    parameter FB_WIDTH  = `VGA_MODE_H_VISIBLE,
    parameter FB_HEIGHT = `VGA_MODE_V_VISIBLE
) (
    input logic clk,
    input logic reset,
    input logic enable,

    input logic                 start,
    input logic [FB_X_BITS-1:0] x0,
    input logic [FB_Y_BITS-1:0] y0,
    input logic [FB_X_BITS-1:0] x1,
    input logic [FB_Y_BITS-1:0] y1,

    output logic [FB_X_BITS-1:0] x,
    output logic [FB_Y_BITS-1:0] y,
    output logic                 done
);
  localparam FB_X_BITS = $clog2(FB_WIDTH);
  localparam FB_Y_BITS = $clog2(FB_HEIGHT);
  localparam CORD_BITS = (FB_X_BITS > FB_Y_BITS) ? FB_X_BITS : FB_Y_BITS;

  logic [FB_X_BITS-1:0] xa;
  logic [FB_Y_BITS-1:0] ya;

  logic [FB_X_BITS-1:0] xb;
  logic [FB_Y_BITS-1:0] yb;

  logic [FB_X_BITS-1:0] x_end;
  logic [FB_Y_BITS-1:0] y_end;

  //
  // Normalize the direction of the line drawing from top to bottom.
  // This is because Breshenham's algorithm doesn't produce symmetrical
  // results from the other direction.
  //
  always_comb begin
    if (y0 > y1) begin
      xa = {1'b0, x1};
      xb = {1'b0, x0};
      ya = {1'b0, y1};
      yb = {1'b0, y0};
    end else begin
      xa = {1'b0, x0};
      xb = {1'b0, x1};
      ya = {1'b0, y0};
      yb = {1'b0, y1};
    end
  end

  // is the line going left to right?
  logic                      left_to_right;

  // error values (signed, so not -1 on the upper bit pos)
  logic signed [CORD_BITS:0] err;
  logic signed [CORD_BITS:0] dx;
  logic signed [CORD_BITS:0] dy;

  // which direction do we go in the next step
  logic                      movx;
  logic                      movy;

  always_comb begin
    if ((err << 1) >= dy) begin
      movx = 1'b1;
      movy = 1'b0;
    end else begin
      movx = 1'b0;
      movy = 1'b1;
    end
  end

  // state machine
  localparam IDLE = 2'b00;
  localparam INIT_0 = 2'b01;
  localparam INIT_1 = 2'b10;
  localparam DRAW = 2'b11;

  logic [1:0] state;

  // Pipeline the calculation of the constants used by the algorithm.
  //
  // See: https://projectf.io/posts/lines-and-triangles/
  // for a discussion of why.
  //
  always_ff @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      done  <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          done <= 1'b0;
          if (start) begin
            state         <= INIT_0;
            left_to_right <= (xa < xb);
          end
        end

        INIT_0: begin
          state <= INIT_1;
          dx    <= left_to_right ? xb - xa : xa - xb;
          dy    <= ya - yb;
        end

        INIT_1: begin
          state <= DRAW;
          err   <= dx + dy;
          x     <= xa;
          y     <= ya;
          x_end <= xb;
          y_end <= yb;
        end

        DRAW: begin
          if (enable) begin
            if (x == x_end && y == y_end) begin
              state <= IDLE;
              done  <= 1;
            end else begin
              if (movx) begin
                x   <= left_to_right ? x + 1 : x - 1;
                err <= err + dy;
              end
              if (movy) begin
                y   <= y + 1;
                err <= err + dx;
              end
              if (movx && movy) begin
                x   <= left_to_right ? x + 1 : x - 1;
                y   <= y + 1;
                err <= err + dy + dx;
              end
            end
          end
        end
      endcase
    end
  end
endmodule

`endif
