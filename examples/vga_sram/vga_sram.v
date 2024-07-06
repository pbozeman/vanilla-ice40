`ifndef VGA_SRAM_V
`define VGA_SRAM_V

`include "directives.v"

`include "sram_controller.v"
`include "vga_sram_pattern_generator.v"
`include "vga_sram_display.v"

module vga_sram #(
    parameter ADDR_BITS = 20,
    parameter DATA_BITS = 16
) (
    // core signals
    input wire clk,
    input wire reset,

    // vga signals
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue,
    output wire vga_hsync,
    output wire vga_vsync,

    // sram addr/data signals
    output wire [ADDR_BITS-1:0] addr_bus,
    inout  wire [DATA_BITS-1:0] data_bus_io,

    // sram control signals
    output wire we_n,
    output wire oe_n,
    output wire ce_n
);

  wire [9:0] column;
  wire [9:0] row;

  wire sram_read_only;
  wire [ADDR_BITS-1:0] sram_addr;
  wire [DATA_BITS-1:0] sram_data_i;
  wire [DATA_BITS-1:0] sram_data_o;
  wire [ADDR_BITS-1:0] sram_data_o_addr;

  wire pattern_done;
  wire [DATA_BITS-1:0] pattern_data;
  wire [ADDR_BITS-1:0] pattern_addr;
  wire [ADDR_BITS-1:0] display_addr;

  sram_controller #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) sram_ctrl (
      .clk(clk),
      .reset(reset),
      .read_only(sram_read_only),
      .addr(sram_addr),
      .data_i(sram_data_i),
      .data_o(sram_data_o),
      .data_o_addr(sram_data_o_addr),
      .addr_bus(addr_bus),
      .data_bus_io(data_bus_io),
      .we_n(we_n),
      .oe_n(oe_n),
      .ce_n(ce_n)
  );

  vga_sram_pattern_generator #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) pattern_gen (
      .clk  (clk),
      .reset(reset),
      .addr (pattern_addr),
      .data (pattern_data),
      .done (pattern_done)
  );

  vga_sram_display #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) vga_disp (
      .clk(clk),
      .reset(reset),
      .pattern_done(pattern_done),
      .sram_addr(display_addr),
      .sram_data(sram_data_o),
      .hsync(vga_hsync),
      .vsync(vga_vsync),
      .red(vga_red),
      .green(vga_green),
      .blue(vga_blue)
  );

  // Mux access to the sram between pattern gen and display
  assign sram_addr = pattern_done ? display_addr : pattern_addr;
  assign sram_data_i = pattern_done ? {DATA_BITS{1'bz}} : pattern_data;
  assign sram_read_only = pattern_done;

endmodule

`endif
