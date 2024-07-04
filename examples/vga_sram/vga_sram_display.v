`ifndef VGA_SRAM_DISPLAY_V
`define VGA_SRAM_DISPLAY_V

`include "directives.v"

module vga_sram_display #(
    parameter ADDR_BITS = 20,
    parameter DATA_BITS = 16
) (
    input wire clk,
    input wire reset,

    input wire pattern_done,

    input wire [9:0] column,
    input wire [9:0] row,

    input  wire [DATA_BITS-1:0] sram_data,
    output reg  [ADDR_BITS-1:0] sram_addr,

    output reg read_only,

    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      sram_addr <= 0;
      read_only <= 0;
      red <= 0;
      green <= 0;
      blue <= 0;
    end else if (pattern_done) begin
      read_only <= 1;
      if (row < 480 && column < 640) begin
        sram_addr <= (row * 640) + column;
        red <= sram_data[15:12];
        green <= sram_data[11:8];
        blue <= sram_data[7:4];
      end else begin
        red   <= 0;
        green <= 0;
        blue  <= 0;
      end
    end
  end

endmodule

`endif
