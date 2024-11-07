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

    output logic [7:0] R_E,
    output logic [7:0] R_F,

    output logic [7:0] R_H,
    output logic [7:0] R_I
);

  logic                 reset;

  // verilator lint_off UNUSEDSIGNAL
  logic [DATA_BITS-1:0] y_data;
  logic [DATA_BITS-1:0] x_data;
  // verilator lint_on UNUSEDSIGNAL

  adc_xy #(
      .DATA_BITS(DATA_BITS)
  ) adc_xy_inst (
      .clk      (CLK),
      .reset    (reset),
      .adc_clk  (L_ADC_CLK_TO_FPGA),
      .adc_x_bus(L_ADC_X),
      .adc_y_bus(L_ADC_Y),
      .adc_x    (x_data),
      .adc_y    (y_data)
  );

  initial_reset initial_reset_inst (
      .clk  (CLK),
      .reset(reset)
  );

  // Output y_data on R_E and R_F
  assign R_E = y_data[7:0];
  assign R_F = {2'b0, L_ADC_CLK_TO_FPGA, 1'b0, CLK, 1'b0, y_data[9:8]};

  // Second copy - use one for LEDs and one for logic analyzer
  assign R_H = y_data[7:0];
  assign R_I = {2'b0, L_ADC_CLK_TO_FPGA, 1'b0, CLK, 1'b0, y_data[9:8]};

endmodule

`endif
