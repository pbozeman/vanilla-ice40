`ifndef SRAM_PATTERN_GENERATOR_V
`define SRAM_PATTERN_GENERATOR_V

`include "directives.sv"

module sram_pattern_generator #(
    parameter integer DATA_BITS = 16
) (
    input  logic                 clk,
    input  logic                 reset,
    input  logic                 inc,
    input  logic [DATA_BITS-1:0] custom,
    output logic [DATA_BITS-1:0] pattern,
    output logic                 done = 1'b0,
    output logic [          2:0] state = 3'b000
);

  // State constants
  localparam [2:0] STATE_ALL_ZEROS = 3'b000, STATE_ALL_ONES = 3'b001,
      STATE_ALTERNATING_10 = 3'b010, STATE_ALTERNATING_01 = 3'b011,
      STATE_HALF_ONES = 3'b100, STATE_ZEROS_AGAIN = 3'b101,
      STATE_CUSTOM = 3'b110, STATE_FINAL = STATE_CUSTOM;

  // Pattern constants
  localparam [DATA_BITS-1:0] PATTERN_ALL_ZEROS = {DATA_BITS{1'b0}},
      PATTERN_ALL_ONES = {DATA_BITS{1'b1}}, PATTERN_ALTERNATING_10 = {
      DATA_BITS / 2{2'b10}}, PATTERN_ALTERNATING_01 = {DATA_BITS / 2{2'b01}},
      PATTERN_HALF_ONES = {DATA_BITS{1'b1}} >> (DATA_BITS / 2);

  always_ff @(posedge clk) begin
    if (reset) begin
      state <= STATE_ALL_ZEROS;
    end else begin
      if (inc) begin
        state <= state + 1'b1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      done <= 1'b0;
    end else begin
      done <= (state == STATE_FINAL);
    end
  end

  always_comb begin
    case (state)
      STATE_ALL_ZEROS:      pattern = PATTERN_ALL_ZEROS;
      STATE_ALL_ONES:       pattern = PATTERN_ALL_ONES;
      STATE_ALTERNATING_10: pattern = PATTERN_ALTERNATING_10;
      STATE_ALTERNATING_01: pattern = PATTERN_ALTERNATING_01;
      STATE_HALF_ONES:      pattern = PATTERN_HALF_ONES;
      STATE_ZEROS_AGAIN:    pattern = PATTERN_ALL_ZEROS;
      STATE_CUSTOM:         pattern = custom;
      default:              pattern = PATTERN_ALL_ZEROS;
    endcase
  end

endmodule

`endif
