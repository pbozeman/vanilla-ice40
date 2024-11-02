`include "directives.sv"

`include "pll_200.sv"

module pll_200_top (
    input  logic CLK,
    output logic LED1,
    output logic LED2
);

  logic clk_200;

  pll_200 pll_200_inst (
      .clk_i(CLK),
      .clk_o(clk_200)
  );

  always_ff @(posedge CLK) begin
    LED1 <= ~LED1;
  end

  always_ff @(posedge clk_200) begin
    LED2 <= ~LED2;
  end

endmodule
