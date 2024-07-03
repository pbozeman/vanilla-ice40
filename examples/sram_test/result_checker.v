// for simulation
`timescale 1ns / 1ps
// avoid undeclared symbols
`default_nettype none

module result_checker #(
    parameter integer DATA_BITS = 16
) (
    input  wire                 clk,
    input  wire                 reset,
    input  wire                 enable,
    input  wire [DATA_BITS-1:0] read_data,
    input  wire [DATA_BITS-1:0] expected_data,
    output reg                  test_pass,
    output reg  [DATA_BITS-1:0] prev_read_data,
    output reg  [DATA_BITS-1:0] prev_expected_data
);

  reg failure_occurred = 0;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      test_pass <= 1'b1;
      failure_occurred <= 1'b0;
      prev_read_data <= {DATA_BITS{1'b0}};
      prev_expected_data <= {DATA_BITS{1'b0}};
    end else if (enable) begin
      if (read_data != expected_data) begin
        test_pass <= 1'b0;
        if (!failure_occurred) begin
          failure_occurred <= 1'b1;
          prev_read_data <= read_data;
          prev_expected_data <= expected_data;
        end
      end
    end else begin
      test_pass <= ~failure_occurred;
    end
  end

endmodule
