`ifndef VGA_SRAM_PATTERN_GENERATOR_V
`define VGA_SRAM_PATTERN_GENERATOR_V

`include "directives.v"

module vga_sram_pattern_generator #(
    parameter ADDR_BITS = 20,
    parameter DATA_BITS = 16
) (
    input wire clk,
    input wire reset,

    output reg [ADDR_BITS-1:0] addr,
    output reg [DATA_BITS-1:0] data,

    output reg done
);

  reg [9:0] current_column;
  reg [9:0] current_row;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      addr <= 0;
      data <= 0;
      done <= 0;
      current_column <= 0;
      current_row <= 0;
    end else if (!done) begin
      if (current_column < 640 && current_row < 480) begin
        if (current_column < 213) begin
          // Red
          data <= 16'b1111_0000_0000_0000;
        end else if (current_column < 426) begin
          // Green
          data <= 16'b0000_1111_0000_0000;
        end else begin
          // Blue
          data <= 16'b0000_0000_1111_0000;
        end

        addr <= (current_row * 640) + current_column;

        if (current_column == 639) begin
          current_column <= 0;
          current_row <= current_row + 1;
        end else begin
          current_column <= current_column + 1;
        end
      end else begin
        done <= 1;
      end
    end
  end

endmodule

`endif
