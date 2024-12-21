`ifndef TLIGHT_TOP_V
`define TLIGHT_TOP_V

`include "directives.sv"

`include "initial_reset.sv"

`ifdef VGA_MODE_640_480_60
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
`else
module tlight_top (
    input logic CLK
);
  // This is a hack to avoid the error that happens as part of auto dependency
  // if there isn't one, i.e. we get an error like:
  //
  // Makefile:118: *** target file '.build/tlight_top.json' has both : and :: entries.  Stop.
  //
  // This should get a better solution, but this works for now and lets use
  // higher resolutions as default in the makefile.

  initial_reset initial_reset_i (
      .clk  (CLK),
      .reset()
  );

endmodule
`endif

`endif
