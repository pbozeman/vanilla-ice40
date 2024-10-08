`ifndef VGA_SRAM_V
`define VGA_SRAM_V

// This is just a POC

`include "directives.v"

`include "axi_sram_controller.v"
`include "vga_sram_pattern_generator.v"
`include "vga_sram_pixel_stream.v"

module vga_sram #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    // core signals
    input wire clk,
    input wire reset,

    // sram controller to io pins
    output wire [AXI_ADDR_WIDTH-1:0] sram_addr,
    inout wire [AXI_DATA_WIDTH-1:0] sram_data,
    output wire sram_we_n,
    output wire sram_oe_n,
    output wire sram_ce_n,

    // vga signals
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue,
    output wire vga_hsync,
    output wire vga_vsync
);
  // AXI-Lite Write Address Channel
  wire [        AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
  wire                              s_axi_awvalid;
  wire                              s_axi_awready;

  // AXI-Lite Write Data Channel
  wire [        AXI_DATA_WIDTH-1:0] s_axi_wdata;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] s_axi_wstrb;
  wire                              s_axi_wvalid;
  wire                              s_axi_wready;

  // AXI-Lite Write Response Channel
  wire [                       1:0] s_axi_bresp;
  wire                              s_axi_bvalid;
  wire                              s_axi_bready;

  // AXI-Lite Read Address Channel
  wire [        AXI_ADDR_WIDTH-1:0] s_axi_araddr;
  wire                              s_axi_arvalid;
  wire                              s_axi_arready;

  // AXI-Lite Read Data Channel
  wire [        AXI_DATA_WIDTH-1:0] s_axi_rdata;
  wire [                       1:0] s_axi_rresp;
  wire                              s_axi_rvalid;
  wire                              s_axi_rready;

  wire                              pattern_done;

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl (
      .axi_aclk(clk),
      .axi_aresetn(~reset),
      .s_axi_awaddr(s_axi_awaddr),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),
      .s_axi_wdata(s_axi_wdata),
      .s_axi_wstrb(s_axi_wstrb),
      .s_axi_wvalid(s_axi_wvalid),
      .s_axi_wready(s_axi_wready),
      .s_axi_bresp(s_axi_bresp),
      .s_axi_bvalid(s_axi_bvalid),
      .s_axi_bready(s_axi_bready),
      .s_axi_araddr(s_axi_araddr),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),
      .s_axi_rdata(s_axi_rdata),
      .s_axi_rresp(s_axi_rresp),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rready(s_axi_rready),
      .sram_addr(sram_addr),
      .sram_data(sram_data),
      .sram_we_n(sram_we_n),
      .sram_oe_n(sram_oe_n),
      .sram_ce_n(sram_ce_n)
  );

  vga_sram_pattern_generator #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) pattern (
      .clk(clk),
      .reset(reset),
      .pattern_done(pattern_done),

      .s_axi_awaddr (s_axi_awaddr),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),

      .s_axi_wdata (s_axi_wdata),
      .s_axi_wstrb (s_axi_wstrb),
      .s_axi_wvalid(s_axi_wvalid),
      .s_axi_wready(s_axi_wready),

      .s_axi_bresp (s_axi_bresp),
      .s_axi_bvalid(s_axi_bvalid),
      .s_axi_bready(s_axi_bready)
  );

  vga_sram_pixel_stream #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) pixel_stream (
      .clk  (clk),
      .reset(reset),
      .start(pattern_done),

      .s_axi_araddr (s_axi_araddr),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),

      .s_axi_rdata (s_axi_rdata),
      .s_axi_rresp (s_axi_rresp),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rready(s_axi_rready),

      .vsync(vga_vsync),
      .hsync(vga_hsync),
      .red  (vga_red),
      .green(vga_green),
      .blue (vga_blue)
  );
endmodule

`endif
