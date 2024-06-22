module vga_top (
    input  wire clk_i,
    output wire led1_o,
    output wire led2_o,
    output wire EF_01,
    output wire EF_02
);

  wire vga_clk;

  pll_vga pll_vga_inst (
      .clk_i(clk_i),
      .clk_o(vga_clk)
  );

  assign led1_o = 1'bZ;
  assign led2_o = 1'bZ;

  assign EF_01  = clk_i;
  assign EF_02  = vga_clk;

endmodule
