`ifndef SRAM_CONTROLLER_V
`define SRAM_CONTROLLER_V

`include "directives.v"

module sram_controller #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // to/from the caller
    input  wire                 clk,
    input  wire                 reset,
    input  wire                 read_only,
    input  wire [ADDR_BITS-1:0] addr,
    input  wire [DATA_BITS-1:0] data_i,
    output reg  [DATA_BITS-1:0] data_o,
    output reg  [ADDR_BITS-1:0] data_o_addr,

    // to/from the chip
    output reg  [ADDR_BITS-1:0] addr_bus,
    inout  wire [DATA_BITS-1:0] data_bus_io,
    output reg                  we_n,
    output reg                  oe_n,
    output wire                 ce_n
);

  reg [DATA_BITS-1:0] write_data_reg = 0;
  reg read_only_reg = 0;

  // Chip select is always active
  assign ce_n = 1'b0;

  // Tristate buffer for data bus
  assign data_bus_io = (read_only_reg) ? {DATA_BITS{1'bz}} : write_data_reg;

  // Main control logic
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      addr_bus <= 0;
      we_n <= 1'b1;
      oe_n <= 1'b1;
      data_o <= 0;
      write_data_reg <= 0;
      read_only_reg <= 0;
    end else begin
      // Register inputs every cycle
      addr_bus <= addr;
      write_data_reg <= data_i;
      read_only_reg <= read_only;

      // Control signals
      we_n <= read_only;
      oe_n <= ~read_only;

      // Read data
      if (read_only_reg) begin
        data_o_addr <= data_bus_io;
        data_o <= data_bus_io;
      end
    end
  end

endmodule

`endif
