// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module sram_controller #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // to/from the caller
    input wire clk_i,
    input wire reset_i,
    input wire rw_i,
    input wire [ADDR_BITS-1:0] addr_i,
    input wire [DATA_BITS-1:0] data_i,
    output reg [DATA_BITS-1:0] data_o,

    // to/from the chip
    output wire [ADDR_BITS-1:0] addr_bus_o,
    inout wire [DATA_BITS-1:0] data_bus_io,
    output wire we_n_o,
    output wire oe_n_o,
    output wire ce_n_o
);

  // control signals
  assign ce_n_o = 1'b0;
  assign we_n_o = (rw_i == 1'b1) ? 1'b1 : 1'b0;
  assign oe_n_o = (rw_i == 1'b1) ? 1'b0 : 1'b1;
  assign addr_bus_o = addr_i;

  // control data bus direction
  assign data_bus_io = (rw_i == 1'b1) ? {DATA_BITS{1'bz}} : data_i;

  // Load data_o register when reading
  always @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      data_o <= {DATA_BITS{1'b0}};
    end else if (rw_i == 1'b1) begin
      data_o <= data_bus_io;
    end
  end

endmodule
