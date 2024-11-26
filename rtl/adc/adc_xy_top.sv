`ifndef ADC_XY_TOP_V
`define ADC_XY_TOP_V

`include "directives.sv"

`include "adc_xy.sv"
`include "initial_reset.sv"

module adc_xy_top #(
    parameter integer DATA_BITS = 10
) (
    input logic                 CLK,
    input logic                 L_ADC_CLK_TO_FPGA,
    input logic [DATA_BITS-1:0] L_ADC_Y,
    input logic [DATA_BITS-1:0] L_ADC_X,
    input logic                 L_ADC_RED,
    input logic                 L_ADC_GRN,
    input logic                 L_ADC_BLU,

    output logic [7:0] R_E,
    output logic [7:0] R_F,

    output logic [7:0] R_H,
    output logic [7:0] R_I
);

  logic                 reset;

  // verilator lint_off UNUSEDSIGNAL
  logic [DATA_BITS-1:0] adc_x;
  logic [DATA_BITS-1:0] adc_y;
  logic                 adc_red;
  logic                 adc_grn;
  logic                 adc_blu;
  // verilator lint_on UNUSEDSIGNAL

  adc_xy #(
      .DATA_BITS(DATA_BITS)
  ) adc_xy_inst (
      .clk       (CLK),
      .reset     (reset),
      .adc_clk   (L_ADC_CLK_TO_FPGA),
      .adc_x_io  (L_ADC_X),
      .adc_y_io  (L_ADC_Y),
      .adc_red_io(L_ADC_RED),
      .adc_grn_io(L_ADC_GRN),
      .adc_blu_io(L_ADC_BLU),
      .adc_x     (adc_x),
      .adc_y     (adc_y),
      .adc_red   (adc_red),
      .adc_grn   (adc_grn),
      .adc_blu   (adc_blu)
  );

  initial_reset initial_reset_inst (
      .clk  (CLK),
      .reset(reset)
  );

  // Output y_data on R_E and R_F
  assign R_E = adc_y[7:0];
  assign R_F = {2'b0, L_ADC_CLK_TO_FPGA, 1'b0, CLK, 1'b0, adc_y[9:8]};

  // Second copy - use one for LEDs and one for logic analyzer
  assign R_H = adc_y[7:0];
  assign R_I = {2'b0, L_ADC_CLK_TO_FPGA, 1'b0, CLK, 1'b0, adc_y[9:8]};

endmodule

`endif
