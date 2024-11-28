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

    input logic [DATA_BITS-1:0] adc_x_io,
    input logic [DATA_BITS-1:0] adc_y_io,
    input logic                 adc_red_io,
    input logic                 adc_grn_io,
    input logic                 adc_blu_io,

    output logic [DATA_BITS-1:0] adc_x,
    output logic [DATA_BITS-1:0] adc_y,
    output logic                 adc_red,
    output logic                 adc_grn,
    output logic                 adc_blu
);

  logic [DATA_BITS-1:0] adc_x_int;
  logic [DATA_BITS-1:0] adc_y_int;
  logic                 adc_red_int;
  logic                 adc_grn_int;
  logic                 adc_blu_int;

  adc_xy #(
      .DATA_BITS(DATA_BITS)
  ) adc_xy_inst (
      .clk       (clk),
      .adc_clk   (adc_clk),
      .reset     (reset),
      .adc_x_io  (adc_x_io),
      .adc_y_io  (adc_y_io),
      .adc_red_io(adc_red_io),
      .adc_grn_io(adc_grn_io),
      .adc_blu_io(adc_blu_io),
      .adc_x     (adc_x_int),
      .adc_y     (adc_y_int),
      .adc_red   (adc_red_int),
      .adc_grn   (adc_grn_int),
      .adc_blu   (adc_blu_int)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      tvalid <= 0;
    end else begin
      if (!tvalid) begin
        tvalid  <= (adc_red_int || adc_grn_int || adc_blu_int);
        adc_x   <= adc_x_int;
        adc_y   <= adc_y_int;
        adc_red <= adc_red_int;
        adc_grn <= adc_grn_int;
        adc_blu <= adc_blu_int;
      end

      // TODO: this is not going as fast as we could
      if (tvalid && tready) begin
        tvalid <= 1'b0;
      end
    end
  end

endmodule

`endif
