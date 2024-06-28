// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module pattern_generator #(
    parameter integer DATA_BITS = 16
) (
    input wire clk,
    input wire reset,
    input wire next_pattern,
    input wire [DATA_BITS-1:0] seed,
    output reg [DATA_BITS-1:0] pattern,
    output reg pattern_done
);

  reg [2:0] pattern_state;

  // states
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      pattern_state <= 3'b000;
      pattern_done  <= 1'b0;
    end else if (next_pattern) begin
      pattern_done  <= (pattern_state == 3'b110);
      pattern_state <= pattern_state + 1;
    end
  end

  // patterns
  always @(*) begin
    if (reset) begin
      pattern = {DATA_BITS{1'b0}};
    end else begin
      case (pattern_state)
        3'b000:  pattern = {DATA_BITS{1'b0}};
        3'b001:  pattern = {DATA_BITS{1'b1}};
        3'b010:  pattern = {DATA_BITS / 2{2'b10}};
        3'b011:  pattern = {DATA_BITS / 2{2'b01}};
        3'b100:  pattern = {DATA_BITS{1'b1}} >> (DATA_BITS / 2);
        3'b101:  pattern = {DATA_BITS{1'b0}};
        default: pattern = seed;
      endcase
    end
  end

endmodule
