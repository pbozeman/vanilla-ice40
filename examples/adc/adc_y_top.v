`ifndef ADC_Y_TOP_V
`define ADC_Y_TOP_V

`include "directives.v"

`include "adc_y.v"

module adc_y_top #(
    parameter integer DATA_BITS = 10
) (
    input wire                 CLK,
    input wire                 L_ADC_CLK_TO_FPGA,
    input wire [DATA_BITS-1:0] L_ADC_Y,

    output wire [7:0] R_E,
    output wire [7:0] R_F,

    output wire [7:0] R_C,
    output wire [7:0] R_D
);

  wire [DATA_BITS-1:0] y_data;

  adc_y #(
      .DATA_BITS(DATA_BITS)
  ) adc_y_inst (
      .clk       (CLK),
      .adc_clk   (L_ADC_CLK_TO_FPGA),
      .y_data_bus(L_ADC_Y),
      .y_data    (y_data)
  );

  // Output y_data on R_E and R_F
  assign R_E = y_data[0:7];
  assign R_F = {2'b0, L_ADC_CLK_TO_FPGA, 1'b0, CLK, 1'b0, y_data[8:9]};

  // Second copy - use one for LEDs and one for logic analyzer
  assign R_C = y_data[0:7];
  assign R_D = {2'b0, L_ADC_CLK_TO_FPGA, 1'b0, CLK, 1'b0, y_data[8:9]};

endmodule

`endif
