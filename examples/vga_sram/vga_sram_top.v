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
    output wire [ADDR_BITS-1:0] R_SRAM_ADDR_BUS,
    inout  wire [DATA_BITS-1:0] R_SRAM_DATA_BUS,

    // sram control signals
    output wire R_SRAM_CS_N,
    output wire R_SRAM_OE_N,
    output wire R_SRAM_WE_N,

    // used for vga signals
    output wire [7:0] R_E,
    output wire [7:0] R_F
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
      .addr_bus(R_SRAM_ADDR_BUS),
      .data_bus_io(R_SRAM_DATA_BUS),
      .we_n(R_SRAM_WE_N),
      .oe_n(R_SRAM_OE_N),
      .ce_n(R_SRAM_CS_N)
  );

  assign LED1 = 1'bz;
  assign LED2 = 1'bz;

  assign R_E[3:0] = vga_red;
  assign R_E[7:4] = vga_blue;
  assign R_F[3:0] = vga_green;
  assign R_F[4] = vga_hsync;
  assign R_F[5] = vga_vsync;

endmodule
`endif
