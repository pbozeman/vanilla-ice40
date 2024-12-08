`ifndef TLIGHT_TOP_V
`define TLIGHT_TOP_V

`include "directives.sv"

`include "initial_reset.sv"
`include "tlight.sv"
`include "vga_mode.sv"
`include "vga_pll.sv"

module tlight_top #(
    parameter  PIXEL_BITS = 12,
    localparam COLOR_BITS = PIXEL_BITS / 3
) (
    input logic CLK,

    // the pmods on my dev board already have constraints named like this,
    // there is a L and R side (for left and right, duh), and A-L, so these
    // are right pmods E and F.
    output logic [7:0] R_E,
    output logic [7:0] R_F
);
  logic                  reset;

  logic [COLOR_BITS-1:0] vga_red;
  logic [COLOR_BITS-1:0] vga_grn;
  logic [COLOR_BITS-1:0] vga_blu;
  logic                  vga_hsync;
  logic                  vga_vsync;

  logic                  clk;

  // Normally I would have the vga_clk and the main clock running
  // independently, and cdc the pixels over, but the challenge was said to
  // only use 1 clock. That said, we need to slow down our 100mhz clock.
  vga_pll vga_pll_i (
      .clk_i(CLK),
      .clk_o(clk)
  );

  initial_reset initial_reset_i (
      .clk  (CLK),
      .reset(reset)
  );

  tlight tlight_i (
      .clk  (clk),
      .reset(reset),

      // vga signals
      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync)
  );

  // digilent vga pmod pinout
  assign R_E[3:0] = vga_red;
  assign R_E[7:4] = vga_blu;
  assign R_F[3:0] = vga_grn;
  assign R_F[4]   = vga_hsync;
  assign R_F[5]   = vga_vsync;
  assign R_F[6]   = 1'b0;
  assign R_F[7]   = 1'b0;

endmodule

`endif
