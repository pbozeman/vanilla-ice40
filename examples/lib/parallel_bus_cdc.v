`ifndef PARALLEL_BUS_CDC_V
`define PARALLEL_BUS_CDC_V

`include "directives.v"

module parallel_bus_cdc #(
    parameter BUS_WIDTH = 10
) (
    input wire clk,

    // external data bus and clock
    input wire                 ext_clk,
    input wire [BUS_WIDTH-1:0] data_bus,

    // data usable in clk clock domain
    output reg [BUS_WIDTH-1:0] data
);

  // Sampled source data
  reg [BUS_WIDTH-1:0] data_bus_reg = 0;

  // Metastability resolution register
  reg [BUS_WIDTH-1:0] data_meta = 0;

  // Sample source data on negative edge of source clock to allow for
  // setup/hold times of external output buffers and mismatched pcb
  // trace lengths.
  always @(negedge ext_clk) begin
    data_bus_reg <= data_bus;
  end

  // 2 flop synchronizer
  always @(posedge clk) begin
    data_meta <= data_bus_reg;
    data <= data_meta;
  end

endmodule

`endif
