`include "directives.v"

`include "pll_200.v"

module pll_200_top (
    input  wire CLK,
    output reg  LED1,
    output reg  LED2
);

  wire clk_200;

  pll_200 pll_200_inst (
      .clk_i(CLK),
      .clk_o(clk_200)
  );

  always @(posedge CLK) begin
    LED1 <= ~LED1;
  end

  always @(posedge clk_200) begin
    LED2 <= ~LED2;
  end

endmodule
