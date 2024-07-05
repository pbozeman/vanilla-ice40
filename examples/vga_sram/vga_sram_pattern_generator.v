`ifndef VGA_SRAM_PATTERN_GENERATOR_V
`define VGA_SRAM_PATTERN_GENERATOR_V

`include "directives.v"

module vga_sram_pattern_generator #(
    parameter ADDR_BITS = 20,
    parameter DATA_BITS = 16
) (
    input wire clk,
    input wire reset,

    output reg  [ADDR_BITS-1:0] addr,
    output wire [DATA_BITS-1:0] data,

    output reg done = 0
);

  reg [9:0] column = 0;
  reg [9:0] row = 0;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      addr <= 0;
      done <= 0;
      column <= 0;
      row <= 0;
    end else if (!done) begin
      if (column < 640) begin
        column <= column + 1;
        addr   <= (row * 640) + column;
      end else begin
        if (row < 480) begin
          column <= 0;
          row <= row + 1;
          addr <= (row + 1) * 640;
        end else begin
          done <= 1;
        end
      end
    end
  end

  assign data[15:12] = (row < 480 && column < 213) ? 4'b1111 : 4'b0000;
  assign data[11:8]  = (row < 480 && column >= 213 && column < 426) ? 4'b1111 : 4'b0000;
  assign data[7:4]   = (row < 480 && column >= 426 && column < 640) ? 4'b1111 : 4'b0000;
  assign data[3:0]   = 4'b0000;

endmodule

`endif
