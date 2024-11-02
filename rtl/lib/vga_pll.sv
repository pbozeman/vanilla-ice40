`ifndef VGA_PLL_V
`define VGA_PLL_V

`include "directives.sv"

`include "vga_mode.sv"

`ifndef SIMULATOR

module vga_pll (
    input  logic clk_i,
    output logic clk_o
);

  logic pll_lock;

  // intermediate clock, see global buffer comment below
  logic clk_int;

  SB_PLL40_CORE #(
      .FEEDBACK_PATH("SIMPLE"),
      .DIVR         (`VGA_MODE_PLL_DIVR),
      .DIVF         (`VGA_MODE_PLL_DIVF),
      .DIVQ         (`VGA_MODE_PLL_DIVQ),
      .FILTER_RANGE (`VGA_MODE_PLL_FILTER_RANGE)
  ) pll_inst (
      .LOCK        (pll_lock),
      .RESETB      (1'b1),
      .BYPASS      (1'b0),
      .REFERENCECLK(clk_i),
      .PLLOUTGLOBAL(clk_int)
  );

  // Hook up PLL output to a global buffer
  //
  // From: FPGA-TN-02052-1-4-iCE40-sysCLOCK-PLL-Design-User-Guide.pdf
  //
  // "Required for a user’s internally generated FPGA signal
  // that is heavily loaded and requires global buffering.
  // For example, a user’s logic-generated clock."

  SB_GB gb_inst (
      .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_int),
      .GLOBAL_BUFFER_OUTPUT        (clk_o)
  );

endmodule

`endif
`endif
