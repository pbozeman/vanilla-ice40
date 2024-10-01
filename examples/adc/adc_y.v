`ifndef ADC_Y_V
`define ADC_Y_V

`include "directives.v"

`include "parallel_bus_cdc.v"

// For now, just pass the results through to some
// io pins and test with a logic analyzer or scope
module adc_y #(
    parameter DATA_BITS = 10
) (
    input wire clk,

    // external data bus and clock
    input wire                 adc_clk,
    input wire [DATA_BITS-1:0] y_data_bus,

    output wire [DATA_BITS-1:0] y_data
);

  parallel_bus_cdc #(
      .BUS_WIDTH(DATA_BITS)
  ) pbus (
      .clk(clk),
      .ext_clk(adc_clk),
      .data_bus(y_data_bus),
      .data(y_data)
  );

endmodule

`endif
