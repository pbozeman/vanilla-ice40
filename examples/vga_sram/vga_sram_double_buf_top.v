
`ifndef VGA_SRAM_DOUBLE_BUF_TOP_V
`define VGA_SRAM_DOUBLE_BUF_TOP_V

`include "directives.v"

`include "vga_pll.v"
`include "vga_sram_double_buf.v"

module vga_sram_double_buf_top #(
    parameter ADDR_BITS = 20,
    parameter DATA_BITS = 16
) (
    // board signals
    input  wire CLK,
    output wire LED1,
    output wire LED2,

    // sram 0
    output wire [ADDR_BITS-1:0] R_SRAM_ADDR_BUS,
    inout  wire [DATA_BITS-1:0] R_SRAM_DATA_BUS,
    output wire                 R_SRAM_CS_N,
    output wire                 R_SRAM_OE_N,
    output wire                 R_SRAM_WE_N,

    // sram 1 buses
    output wire [ADDR_BITS-1:0] L_SRAM_ADDR_BUS,
    inout  wire [DATA_BITS-1:0] L_SRAM_DATA_BUS,
    output wire                 L_SRAM_CS_N,
    output wire                 L_SRAM_OE_N,
    output wire                 L_SRAM_WE_N,

    // used for vga signals
    output wire [7:0] R_E,
    output wire [7:0] R_F
);

  wire       reset = 0;
  wire       pixel_clk;

  wire [3:0] vga_red;
  wire [3:0] vga_green;
  wire [3:0] vga_blue;
  wire       vga_hsync;
  wire       vga_vsync;

  vga_pll vga_pll_inst (
      .clk_i(CLK),
      .clk_o(pixel_clk)
  );

  vga_sram_double_buf #(
      .AXI_ADDR_WIDTH(ADDR_BITS),
      .AXI_DATA_WIDTH(DATA_BITS)
  ) vga_sram_inst (
      .clk      (CLK),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .vga_red  (vga_red),
      .vga_green(vga_green),
      .vga_blue (vga_blue),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),

      // sram 0 signals
      .sram0_io_addr(R_SRAM_ADDR_BUS),
      .sram0_io_data(R_SRAM_DATA_BUS),
      .sram0_io_we_n(R_SRAM_WE_N),
      .sram0_io_oe_n(R_SRAM_OE_N),
      .sram0_io_ce_n(R_SRAM_CS_N),

      // sram 1 signals
      .sram1_io_addr(L_SRAM_ADDR_BUS),
      .sram1_io_data(L_SRAM_DATA_BUS),
      .sram1_io_we_n(L_SRAM_WE_N),
      .sram1_io_oe_n(L_SRAM_OE_N),
      .sram1_io_ce_n(L_SRAM_CS_N)
  );

  assign LED1     = 1'bz;
  assign LED2     = 1'bz;

  assign R_E[3:0] = vga_red;
  assign R_E[7:4] = vga_blue;
  assign R_F[3:0] = vga_green;
  assign R_F[4]   = vga_hsync;
  assign R_F[5]   = vga_vsync;

endmodule
`endif
