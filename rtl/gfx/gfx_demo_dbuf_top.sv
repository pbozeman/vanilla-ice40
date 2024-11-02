`ifndef GFX_DEMO_DBUF_TOP_V
`define GFX_DEMO_DBUF_TOP_V

`include "directives.sv"

`include "gfx_demo_dbuf.sv"
`include "initial_reset.sv"
`include "vga_mode.sv"
`include "vga_pll.sv"

module gfx_demo_dbuf_top #(
    parameter VGA_WIDTH  = `VGA_MODE_H_VISIBLE,
    parameter VGA_HEIGHT = `VGA_MODE_V_VISIBLE,
    parameter PIXEL_BITS = 12,
    parameter ADDR_BITS  = 20,
    parameter DATA_BITS  = 16
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

  initial_reset u_initial_reset (
      .clk  (CLK),
      .reset(reset)
  );

  gfx_demo_dbuf #(
      .AXI_ADDR_WIDTH(ADDR_BITS),
      .AXI_DATA_WIDTH(DATA_BITS)
  ) u_demo (
      .clk      (CLK),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      // vga signals
      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
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

  // digilent vga pmod pinout
  assign R_E[3:0] = vga_red;
  assign R_E[7:4] = vga_blu;
  assign R_F[3:0] = vga_grn;
  assign R_F[4]   = vga_hsync;
  assign R_F[5]   = vga_vsync;

endmodule

`endif
