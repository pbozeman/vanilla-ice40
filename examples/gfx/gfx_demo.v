`ifndef GFX_DEMO_V
`define GFX_DEMO_V


`include "directives.v"

`include "gfx_test_pattern.v"

module gfx_demo #(
    parameter VGA_WIDTH  = 640,
    parameter VGA_HEIGHT = 480
) (
    input wire clk,
    input wire reset,

    output wire [FB_X_BITS-1:0] x,
    output wire [FB_Y_BITS-1:0] y
);
  localparam FB_X_BITS = $clog2(VGA_WIDTH);
  localparam FB_Y_BITS = $clog2(VGA_HEIGHT);

  reg  enable;
  wire last;
  wire valid;

  gfx_test_pattern u_pat (
      .clk   (clk),
      .reset (reset),
      .enable(enable),
      .x     (x),
      .y     (y),
      // .color(color),
      .valid (valid),
      .last  (last)
  );

  always @(posedge clk) begin
    if (reset) begin
      enable <= 1'b1;
    end
  end

endmodule

`endif
