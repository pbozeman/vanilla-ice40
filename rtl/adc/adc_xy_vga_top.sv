`ifndef ADC_XY_VGA_TOP_V
`define ADC_XY_VGA_TOP_V

`include "directives.sv"

`include "adc_xy_vga.sv"
`include "initial_reset.sv"
`include "vga_mode.sv"
`include "vga_pll.sv"

module adc_xy_vga_top #(
    parameter  SRAM_ADDR_BITS = 20,
    parameter  SRAM_DATA_BITS = 16,
    parameter  ADC_DATA_BITS  = 10,
    parameter  PIXEL_BITS     = 12,
    parameter  META_BITS      = 4,
    localparam COLOR_BITS     = PIXEL_BITS / 3
) (
    input logic                     CLK,
    input logic                     L_ADC_CLK_TO_FPGA,
    input logic [ADC_DATA_BITS-1:0] L_ADC_Y,
    input logic [ADC_DATA_BITS-1:0] L_ADC_X,

    // sram 0
    output logic [SRAM_ADDR_BITS-1:0] R_SRAM_ADDR_BUS,
    inout  wire  [SRAM_DATA_BITS-1:0] R_SRAM_DATA_BUS,
    output logic                      R_SRAM_CS_N,
    output logic                      R_SRAM_OE_N,
    output logic                      R_SRAM_WE_N,

    output logic [7:0] R_E,
    output logic [7:0] R_F
);
  logic                  reset;

  logic [COLOR_BITS-1:0] vga_red;
  logic [COLOR_BITS-1:0] vga_grn;
  logic [COLOR_BITS-1:0] vga_blu;
  // verilator lint_off UNUSEDSIGNAL
  logic [ META_BITS-1:0] vga_meta;
  // verilator lint_on UNUSEDSIGNAL
  logic                  vga_hsync;
  logic                  vga_vsync;

  logic                  pixel_clk;
  vga_pll vga_pll_inst (
      .clk_i(CLK),
      .clk_o(pixel_clk)
  );

  initial_reset initial_reset_inst (
      .clk  (CLK),
      .reset(reset)
  );

  adc_xy_vga u_demo (
      .clk      (CLK),
      .adc_clk  (L_ADC_CLK_TO_FPGA),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      // adc signals
      .adc_x_io(L_ADC_X),
      .adc_y_io(L_ADC_Y),

      // vga signals
      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_meta (vga_meta),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),

      // sram 0 signals
      .sram0_io_addr(R_SRAM_ADDR_BUS),
      .sram0_io_data(R_SRAM_DATA_BUS),
      .sram0_io_we_n(R_SRAM_WE_N),
      .sram0_io_oe_n(R_SRAM_OE_N),
      .sram0_io_ce_n(R_SRAM_CS_N)
  );


  // digilent vga pmod pinout
  assign R_E[3:0] = vga_red;
  assign R_E[7:4] = vga_blu;
  assign R_F[3:0] = vga_grn;
  assign R_F[4]   = vga_hsync;
  assign R_F[5]   = vga_vsync;
  assign R_F[6]   = 1'bz;
  assign R_F[7]   = 1'bz;

endmodule

`endif
