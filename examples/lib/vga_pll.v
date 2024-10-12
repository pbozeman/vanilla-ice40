`ifndef VGA_PLL
`define VGA_PLL

`include "directives.v"

`ifndef SIMULATOR

`define PLL_DIVR (4'd0)
`define PLL_DIVF (7'd7)
`define PLL_DIVQ (3'd5)
`define PLL_FILTER_RANGE (3'd5)

module vga_pll (
    input  wire clk_i,
    output wire clk_o
);

  wire pll_lock;

  // intermediate clock, see global buffer comment below
  wire clk_int;

  SB_PLL40_CORE #(
      .FEEDBACK_PATH("SIMPLE"),
      .DIVR         (`PLL_DIVR),
      .DIVF         (`PLL_DIVF),
      .DIVQ         (`PLL_DIVQ),
      .FILTER_RANGE (`PLL_FILTER_RANGE)
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
