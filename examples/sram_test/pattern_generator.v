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
    output wire [DATA_BITS-1:0] pattern,
    output reg pattern_done = 1'b0,
    output reg [2:0] pattern_state = 3'b000
);

  reg [DATA_BITS-1:0] pattern_internal = 0;
  assign pattern = pattern_internal;

  wire [DATA_BITS-1:0] seed_internal = seed - 1;

  // State constants
  localparam [2:0]
        STATE_ALL_ZEROS      = 3'b000,
        STATE_ALL_ONES       = 3'b001,
        STATE_ALTERNATING_10 = 3'b010,
        STATE_ALTERNATING_01 = 3'b011,
        STATE_HALF_ONES      = 3'b100,
        STATE_ZEROS_AGAIN    = 3'b101,
        STATE_SEED           = 3'b110,
        STATE_FINAL          = STATE_SEED;

  // Pattern constants
  localparam [DATA_BITS-1:0]
        PATTERN_ALL_ZEROS      = {DATA_BITS{1'b0}},
        PATTERN_ALL_ONES       = {DATA_BITS{1'b1}},
        PATTERN_ALTERNATING_10 = {DATA_BITS/2{2'b10}},
        PATTERN_ALTERNATING_01 = {DATA_BITS/2{2'b01}},
        PATTERN_HALF_ONES      = {DATA_BITS{1'b1}} >> (DATA_BITS / 2);

  always @(posedge next_pattern or posedge reset) begin
    if (reset) begin
      pattern_state <= STATE_ALL_ZEROS;
      pattern_done  <= 1'b0;
    end else begin
      pattern_done  <= (pattern_state == STATE_FINAL);
      pattern_state <= pattern_state + 1'b1;
    end
  end

  always @(*) begin
    if (reset) begin
      pattern_internal = 0;
    end else begin
      case (pattern_state)
        STATE_ALL_ZEROS:      pattern_internal = PATTERN_ALL_ZEROS;
        STATE_ALL_ONES:       pattern_internal = PATTERN_ALL_ONES;
        STATE_ALTERNATING_10: pattern_internal = PATTERN_ALTERNATING_10;
        STATE_ALTERNATING_01: pattern_internal = PATTERN_ALTERNATING_01;
        STATE_HALF_ONES:      pattern_internal = PATTERN_HALF_ONES;
        STATE_ZEROS_AGAIN:    pattern_internal = PATTERN_ALL_ZEROS;
        STATE_SEED:           pattern_internal = seed;
        default:              pattern_internal = PATTERN_ALL_ZEROS;
      endcase
    end

  end

endmodule
