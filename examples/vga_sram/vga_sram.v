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

  // signals as it comes from the sram stream
  wire [3:0] sram_vga_red;
  wire [3:0] sram_vga_green;
  wire [3:0] sram_vga_blue;
  wire sram_vga_hsync;
  wire sram_vga_vsync;
  wire sram_vga_data_valid;

  //
  // VGA data marshaling and unmarshaling on for going in and
  // out of the fifo. The sram_ side is in the writer clock
  // domain and vga_ is in the reader.
  //
  localparam VGA_DATA_WIDTH = 14;

  wire [VGA_DATA_WIDTH-1:0] sram_vga_data;
  wire [VGA_DATA_WIDTH-1:0] vga_data;

  assign sram_vga_data = {
    sram_vga_hsync, sram_vga_vsync, sram_vga_red, sram_vga_green, sram_vga_blue
  };

  assign vga_hsync = vga_data[13];
  assign vga_vsync = vga_data[12];
  assign vga_red = vga_data[11:8];
  assign vga_green = vga_data[7:4];
  assign vga_blue = vga_data[3:0];

  vga_sram_pixel_stream #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) pixel_stream (
      .clk(clk),
      .reset(reset),
      .enable(pattern_done & !fifo_almost_full),

      .s_axi_araddr (s_axi_araddr),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),

      .s_axi_rdata (s_axi_rdata),
      .s_axi_rresp (s_axi_rresp),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rready(s_axi_rready),

      .vsync(sram_vga_vsync),
      .hsync(sram_vga_hsync),
      .red  (sram_vga_red),
      .green(sram_vga_green),
      .blue (sram_vga_blue),
      .valid(sram_vga_data_valid)
  );

  wire fifo_almost_full;
  wire fifo_full;
  wire fifo_empty;
  wire vga_ready;

  assign vga_ready = 1'b1;

  cdc_fifo #(
      .DATA_WIDTH(VGA_DATA_WIDTH)
  ) fifo (
      // Write clock domain
      .w_clk(clk),
      .w_rst_n(~reset),
      .w_inc(sram_vga_data_valid),
      .w_data(sram_vga_data),
      .w_full(fifo_full),
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
