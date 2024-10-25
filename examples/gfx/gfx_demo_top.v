`ifndef GFX_DEMO_TOP_V
`define GFX_DEMO_TOP_V

`include "directives.v"

`include "initial_reset.v"
`include "gfx_demo.v"

module gfx_demo_top #(
    parameter VGA_WIDTH  = 640,
    parameter VGA_HEIGHT = 480
) (
    // board signals
    input  wire CLK,
    output wire LED1,
    output wire LED2,

    output wire [7:0] R_E,
    output wire [7:0] R_F,

    output wire [7:0] R_H,
    output wire [7:0] R_I
);
  localparam FB_X_BITS = $clog2(VGA_WIDTH);
  localparam FB_Y_BITS = $clog2(VGA_HEIGHT);

  reg                 reset;

  reg [FB_X_BITS-1:0] x;
  reg [FB_Y_BITS-1:0] y;

  initial_reset u_initial_reset (
      .clk  (CLK),
      .reset(reset)
  );

  gfx_demo u_demo (
      .clk  (CLK),
      .reset(reset),
      .x    (x),
      .y    (y)
  );

  assign LED1     = 1'bz;
  assign LED2     = 1'bz;

  assign R_E[7:0] = x[0:8];
  assign R_F[7:6] = x[9:10];
  assign R_F[5:0] = 6'b000000;

  assign R_H[7:0] = y[0:8];
  assign R_I[7:6] = y[9:10];
  assign R_I[5:0] = 6'b000000;

endmodule

`endif
