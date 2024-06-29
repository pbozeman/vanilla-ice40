// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module address_generator #(
    parameter integer ADDR_BITS = 20
) (
    input wire clk,
    input wire reset,
    input wire next_addr,
    output reg [ADDR_BITS-1:0] addr = 0,
    output wire addr_done
);


  assign addr_done = (addr == {ADDR_BITS{1'b1}});
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      addr <= {ADDR_BITS{1'b0}};
    end else if (next_addr) begin
      if (addr < {ADDR_BITS{1'b1}}) begin
        addr <= addr + 1;
      end
    end
  end

endmodule
