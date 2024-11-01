`ifndef ADC_XY_VGA_TOP_V
`define ADC_XY_VGA_TOP_V

`include "directives.v"

`include "adc_xy_vga.v"
`include "initial_reset.v"
`include "vga_pll.v"

module adc_xy_vga_top #(
    parameter VGA_WIDTH      = 640,
    parameter VGA_HEIGHT     = 480,
    parameter PIXEL_BITS     = 12,
    parameter SRAM_ADDR_BITS = 20,
    parameter SRAM_DATA_BITS = 16,
    parameter ADC_DATA_BITS  = 10
) (
    input wire                     CLK,
    input wire                     L_ADC_CLK_TO_FPGA,
    input wire [ADC_DATA_BITS-1:0] L_ADC_Y,
    input wire [ADC_DATA_BITS-1:0] L_ADC_X,

    // sram 0
    output wire [SRAM_ADDR_BITS-1:0] R_SRAM_ADDR_BUS,
    inout  wire [SRAM_DATA_BITS-1:0] R_SRAM_DATA_BUS,
    output wire                      R_SRAM_CS_N,
    output wire                      R_SRAM_OE_N,
    output wire                      R_SRAM_WE_N,

    output wire [7:0] R_E,
    output wire [7:0] R_F
);
  localparam FB_X_BITS = $clog2(VGA_WIDTH);
  localparam FB_Y_BITS = $clog2(VGA_HEIGHT);

  localparam COLOR_BITS = PIXEL_BITS / 3;

  reg                   reset;

  wire [COLOR_BITS-1:0] vga_red;
  wire [COLOR_BITS-1:0] vga_grn;
  wire [COLOR_BITS-1:0] vga_blu;
  wire                  vga_hsync;
  wire                  vga_vsync;

  wire                  pixel_clk;
  vga_pll vga_pll_inst (
      .clk_i(CLK),
      .clk_o(pixel_clk)
  );

  initial_reset initial_reset_inst (
      .clk  (CLK),
      .reset(reset)
  );

  adc_xy_vga #(
      .ADC_DATA_BITS (ADC_DATA_BITS),
      .VGA_WIDTH     (VGA_WIDTH),
      .VGA_HEIGHT    (VGA_HEIGHT),
      .PIXEL_BITS    (PIXEL_BITS),
      .AXI_ADDR_WIDTH(SRAM_ADDR_BITS),
      .AXI_DATA_WIDTH(SRAM_DATA_BITS)
  ) u_demo (
      .clk      (CLK),
      .adc_clk  (L_ADC_CLK_TO_FPGA),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      // adc signals
      .adc_x_bus(L_ADC_X),
      .adc_y_bus(L_ADC_Y),

      // vga signals
      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),

      // sram signals
      .sram_io_addr(R_SRAM_ADDR_BUS),
      .sram_io_data(R_SRAM_DATA_BUS),
      .sram_io_we_n(R_SRAM_WE_N),
      .sram_io_oe_n(R_SRAM_OE_N),
      .sram_io_ce_n(R_SRAM_CS_N)
  );


  // digilent vga pmod pinout
  assign R_E[3:0] = vga_red;
  assign R_E[7:4] = vga_blu;
  assign R_F[3:0] = vga_grn;
  assign R_F[4]   = vga_hsync;
  assign R_F[5]   = vga_vsync;

endmodule

`endif