`ifndef VGA_SRAM_TOP_V
`define VGA_SRAM_TOP_V

`include "directives.v"

`include "vga_pll.v"
`include "vga_sram.v"

module vga_sram_top #(
    parameter ADDR_BITS = 20,
    parameter DATA_BITS = 16
) (
    // board signals
    input  wire CLK,
    output wire LED1,
    output wire LED2,

    // sram buses
    output wire [ADDR_BITS-1:0] SRAM_ADDR_BUS,
    inout  wire [DATA_BITS-1:0] SRAM_DATA_BUS,

    // sram control signals
    output wire SRAM_CS_N,
    output wire SRAM_OE_N,
    output wire SRAM_WE_N,

    // used for vga signals
    output wire [7:0] BA_PINS,
    output wire [7:0] DC_PINS
);

  wire reset = 0;
  wire vga_clk;

  wire [3:0] vga_red;
  wire [3:0] vga_green;
  wire [3:0] vga_blue;
  wire vga_hsync;
  wire vga_vsync;

  vga_pll vga_pll_inst (
      .clk_i(CLK),
      .clk_o(vga_clk)
  );

  vga_sram #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) vga_sram_inst (
      .clk  (vga_clk),
      .reset(reset),

      .vga_red  (vga_red),
      .vga_green(vga_green),
      .vga_blue (vga_blue),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),

      // sram signals
      .addr_bus(SRAM_ADDR_BUS),
      .data_bus_io(SRAM_DATA_BUS),
      .we_n(SRAM_WE_N),
      .oe_n(SRAM_OE_N),
      .ce_n(SRAM_CS_N)
  );

  assign LED1 = 1'bz;
  assign LED2 = 1'bz;

  assign BA_PINS[3:0] = vga_red;
  assign BA_PINS[7:4] = vga_blue;
  assign DC_PINS[3:0] = vga_green;
  assign DC_PINS[4] = vga_hsync;
  assign DC_PINS[5] = vga_vsync;

endmodule
`endif
