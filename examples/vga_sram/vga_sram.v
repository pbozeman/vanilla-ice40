`ifndef VGA_SRAM_V
`define VGA_SRAM_V

// This is just a POC

`include "directives.v"

`include "axi_sram_controller.v"
`include "cdc_fifo.v"
`include "vga_sram_pattern_generator.v"
`include "vga_sram_pixel_stream.v"

module vga_sram #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    // core signals
    input wire clk,
    input wire pixel_clk,
    input wire reset,

    // sram controller to io pins
    output wire [AXI_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram_io_data,
    output wire                      sram_io_we_n,
    output wire                      sram_io_oe_n,
    output wire                      sram_io_ce_n,

    // vga signals
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue,
    output wire       vga_hsync,
    output wire       vga_vsync
);
  // AXI-Lite Write Address Channel
  wire [        AXI_ADDR_WIDTH-1:0] axi_awaddr;
  wire                              axi_awvalid;
  wire                              axi_awready;

  // AXI-Lite Write Data Channel
  wire [        AXI_DATA_WIDTH-1:0] axi_wdata;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] axi_wstrb;
  wire                              axi_wvalid;
  wire                              axi_wready;

  // AXI-Lite Write Response Channel
  wire [                       1:0] axi_bresp;
  wire                              axi_bvalid;
  wire                              axi_bready;

  // AXI-Lite Read Address Channel
  wire [        AXI_ADDR_WIDTH-1:0] axi_araddr;
  wire                              axi_arvalid;
  wire                              axi_arready;

  // AXI-Lite Read Data Channel
  wire [        AXI_DATA_WIDTH-1:0] axi_rdata;
  wire [                       1:0] axi_rresp;
  wire                              axi_rvalid;
  wire                              axi_rready;

  wire                              pattern_done;

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl (
      .axi_clk     (clk),
      .axi_resetn  (~reset),
      .axi_awaddr  (axi_awaddr),
      .axi_awvalid (axi_awvalid),
      .axi_awready (axi_awready),
      .axi_wdata   (axi_wdata),
      .axi_wstrb   (axi_wstrb),
      .axi_wvalid  (axi_wvalid),
      .axi_wready  (axi_wready),
      .axi_bresp   (axi_bresp),
      .axi_bvalid  (axi_bvalid),
      .axi_bready  (axi_bready),
      .axi_araddr  (axi_araddr),
      .axi_arvalid (axi_arvalid),
      .axi_arready (axi_arready),
      .axi_rdata   (axi_rdata),
      .axi_rresp   (axi_rresp),
      .axi_rvalid  (axi_rvalid),
      .axi_rready  (axi_rready),
      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  vga_sram_pattern_generator #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) pattern (
      .clk         (clk),
      .reset       (reset),
      .pattern_done(pattern_done),

      .axi_awaddr (axi_awaddr),
      .axi_awvalid(axi_awvalid),
      .axi_awready(axi_awready),

      .axi_wdata (axi_wdata),
      .axi_wstrb (axi_wstrb),
      .axi_wvalid(axi_wvalid),
      .axi_wready(axi_wready),

      .axi_bresp (axi_bresp),
      .axi_bvalid(axi_bvalid),
      .axi_bready(axi_bready)
  );

  // signals as it comes from the sram stream
  wire [3:0] sram_vga_red;
  wire [3:0] sram_vga_green;
  wire [3:0] sram_vga_blue;
  wire       sram_vga_hsync;
  wire       sram_vga_vsync;
  wire       sram_vga_data_valid;

  //
  // VGA data marshaling and unmarshaling on for going in and
  // out of the fifo. The sram_ side is in the writer clock
  // domain and vga_ is in the reader.
  //
  // FIXME: remove the +20 for column/row
  localparam VGA_DATA_WIDTH = 14 + 20;

  wire [VGA_DATA_WIDTH-1:0] sram_vga_data;
  wire [VGA_DATA_WIDTH-1:0] vga_data;

  // FIXME: remove column/row
  assign sram_vga_data = {
    column,
    row,
    sram_vga_hsync,
    sram_vga_vsync,
    sram_vga_red,
    sram_vga_green,
    sram_vga_blue
  };

  assign vga_hsync = vga_data[13];
  assign vga_vsync = vga_data[12];
  assign vga_red = vga_data[11:8];
  assign vga_green = vga_data[7:4];
  assign vga_blue = vga_data[3:0];

  // FIXME: remove column/row
  wire [9:0] vga_column = vga_data[33:24];
  wire [9:0] vga_row = vga_data[23:14];

  wire [9:0] column;
  wire [9:0] row;

  vga_sram_pixel_stream #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) pixel_stream (
      .clk   (clk),
      .reset (reset),
      .enable(pattern_done & !fifo_almost_full),

      .axi_araddr (axi_araddr),
      .axi_arvalid(axi_arvalid),
      .axi_arready(axi_arready),

      .axi_rdata (axi_rdata),
      .axi_rresp (axi_rresp),
      .axi_rvalid(axi_rvalid),
      .axi_rready(axi_rready),

      .vsync(sram_vga_vsync),
      .hsync(sram_vga_hsync),
      .red  (sram_vga_red),
      .green(sram_vga_green),
      .blue (sram_vga_blue),
      .valid(sram_vga_data_valid),

      // FIXME: remove column/row
      .column(column),
      .row   (row)
  );

  wire fifo_almost_full;
  // verilator lint_off UNUSEDSIGNAL
  wire fifo_full;
  wire fifo_empty;
  // verilator lint_on UNUSEDSIGNAL
  wire vga_ready;

  assign vga_ready = 1'b1;

  cdc_fifo #(
      .DATA_WIDTH(VGA_DATA_WIDTH)
  ) fifo (
      // Write clock domain
      .w_clk        (clk),
      .w_rst_n      (~reset),
      .w_inc        (sram_vga_data_valid),
      .w_data       (sram_vga_data),
      .w_full       (fifo_full),
      .w_almost_full(fifo_almost_full),

      .r_clk  (pixel_clk),
      .r_rst_n(~reset),
      .r_inc  (vga_ready),

      // Read clock domain outputs
      .r_empty(fifo_empty),
      .r_data (vga_data)
  );

endmodule

`endif
