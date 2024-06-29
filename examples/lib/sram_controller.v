// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module sram_controller #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // to/from the caller
    input wire clk,
    input wire reset,
    input wire read_only,
    input wire [ADDR_BITS-1:0] addr,
    input wire [DATA_BITS-1:0] data_i,
    output reg [DATA_BITS-1:0] data_o,

    // to/from the chip
    output wire [ADDR_BITS-1:0] addr_bus,
    inout wire [DATA_BITS-1:0] data_bus_io,
    output wire we_n,
    output wire oe_n,
    output wire ce_n
);

  // control signals
  assign ce_n = 1'b0;
  assign we_n = (read_only == 1'b1) ? 1'b1 : 1'b0;
  assign oe_n = (read_only == 1'b1) ? 1'b0 : 1'b1;
  assign addr_bus = addr;

  // control data bus direction
  assign data_bus_io = (read_only == 1'b1) ? {DATA_BITS{1'bz}} : data_i;

  // Load data_o register when reading
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      data_o <= {DATA_BITS{1'b0}};
    end else if (read_only == 1'b1) begin
      data_o <= data_bus_io;
    end
  end

endmodule
