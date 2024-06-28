// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module result_checker #(
    parameter integer DATA_BITS = 16
) (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [DATA_BITS-1:0] read_data,
    input wire [DATA_BITS-1:0] expected_data,
    output wire test_pass
);

  assign test_pass = (!enable || read_data == expected_data);

endmodule
