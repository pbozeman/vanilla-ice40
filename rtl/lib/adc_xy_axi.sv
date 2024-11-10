`ifndef ADC_XY_AXI_V
`define ADC_XY_AXI_V

`include "directives.sv"

`include "adc_xy.sv"

module adc_xy_axi #(
    parameter DATA_BITS = 10
) (
    input logic clk,
    input logic adc_clk,
    input logic reset,

    output logic tvalid,
    input  logic tready,

    input logic [DATA_BITS-1:0] adc_x_bus,
    input logic [DATA_BITS-1:0] adc_y_bus,

    output logic [DATA_BITS-1:0] adc_x,
    output logic [DATA_BITS-1:0] adc_y
);

  logic [DATA_BITS-1:0] adc_x_int;
  logic [DATA_BITS-1:0] adc_y_int;

  adc_xy #(
      .DATA_BITS(DATA_BITS)
  ) adc_xy_inst (
      .clk      (clk),
      .adc_clk  (adc_clk),
      .reset    (reset),
      .adc_x_bus(adc_x_bus),
      .adc_y_bus(adc_y_bus),
      .adc_x    (adc_x_int),
      .adc_y    (adc_y_int)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      tvalid <= 0;
    end else begin
      if (!tvalid) begin
        tvalid <= 1'b1;
        adc_x  <= adc_x_int;
        adc_y  <= adc_y_int;
      end else begin
        if (tready) begin
          adc_x <= adc_x_int;
          adc_y <= adc_y_int;
        end
      end
    end
  end

endmodule

`endif
