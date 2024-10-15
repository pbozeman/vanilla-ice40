`ifndef VGA_SRAM_DOUBLE_BUF_V
`define VGA_SRAM_DOUBLE_BUF_V

`include "directives.v"

// Quick poc of the how double buffering will work using
// the axi 2x2. (The content isn't changing yet.)

`include "axi_2x2.v"
`include "axi_sram_controller.v"
`include "cdc_fifo.v"
`include "detect_rising.v"
`include "vga_sram_pattern_generator.v"
`include "vga_sram_pixel_stream.v"

module vga_sram_double_buf #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    // core signals
    input wire clk,
    input wire pixel_clk,
    input wire reset,

    // sram0 controller to io pins
    output wire [AXI_ADDR_WIDTH-1:0] sram0_io_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram0_io_data,
    output wire                      sram0_io_we_n,
    output wire                      sram0_io_oe_n,
    output wire                      sram0_io_ce_n,

    // sram1 controller to io pins
    output wire [AXI_ADDR_WIDTH-1:0] sram1_io_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram1_io_data,
    output wire                      sram1_io_we_n,
    output wire                      sram1_io_oe_n,
    output wire                      sram1_io_ce_n,

    // vga signals
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue,
    output wire       vga_hsync,
    output wire       vga_vsync
);
  //
  // Pixel Pattern Gen
  //
  wire [        AXI_ADDR_WIDTH-1:0] gen_axi_awaddr;
  wire                              gen_axi_awvalid;
  wire                              gen_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] gen_axi_wdata;
  wire                              gen_axi_wvalid;
  wire                              gen_axi_wready;
  wire                              gen_axi_bready;
  wire                              gen_axi_arvalid;

  // We only write with the pixel gen, and we don't
  // check for write errors.
  // verilator lint_off UNUSEDSIGNAL
  wire [        AXI_ADDR_WIDTH-1:0] gen_axi_araddr;
  wire                              gen_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] gen_axi_rdata;
  wire                              gen_axi_rvalid;
  wire                              gen_axi_rready;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] gen_axi_wstrb;
  wire [                       1:0] gen_axi_bresp;
  wire                              gen_axi_bvalid;
  wire [                       1:0] gen_axi_rresp;
  // verilator lint_on UNUSEDSIGNAL

  //
  // VGA
  //
  wire [        AXI_ADDR_WIDTH-1:0] vga_axi_araddr;
  wire                              vga_axi_arvalid;
  wire                              vga_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] vga_axi_rdata;
  wire                              vga_axi_rvalid;
  wire                              vga_axi_rready;
  wire                              vga_axi_awvalid;
  wire                              vga_axi_wvalid;

  // We only read on the VGA side, and we don't check for
  // read errors.
  // verilator lint_off UNUSEDSIGNAL
  wire [        AXI_ADDR_WIDTH-1:0] vga_axi_awaddr;
  wire                              vga_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] vga_axi_wdata;
  wire                              vga_axi_wready;
  wire                              vga_axi_bready;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] vga_axi_wstrb;
  wire [                       1:0] vga_axi_bresp;
  wire                              vga_axi_bvalid;
  wire [                       1:0] vga_axi_rresp;
  // verilator lint_on UNUSEDSIGNAL

  // SRAM 0
  wire [        AXI_ADDR_WIDTH-1:0] sram0_axi_awaddr;
  wire                              sram0_axi_awvalid;
  wire                              sram0_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] sram0_axi_wdata;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] sram0_axi_wstrb;
  wire                              sram0_axi_wvalid;
  wire                              sram0_axi_wready;
  wire [                       1:0] sram0_axi_bresp;
  wire                              sram0_axi_bvalid;
  wire                              sram0_axi_bready;
  wire [        AXI_ADDR_WIDTH-1:0] sram0_axi_araddr;
  wire                              sram0_axi_arvalid;
  wire                              sram0_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] sram0_axi_rdata;
  wire [                       1:0] sram0_axi_rresp;
  wire                              sram0_axi_rvalid;
  wire                              sram0_axi_rready;

  // SRAM 1
  wire [        AXI_ADDR_WIDTH-1:0] sram1_axi_awaddr;
  wire                              sram1_axi_awvalid;
  wire                              sram1_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] sram1_axi_wdata;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] sram1_axi_wstrb;
  wire                              sram1_axi_wvalid;
  wire                              sram1_axi_wready;
  wire [                       1:0] sram1_axi_bresp;
  wire                              sram1_axi_bvalid;
  wire                              sram1_axi_bready;
  wire [        AXI_ADDR_WIDTH-1:0] sram1_axi_araddr;
  wire                              sram1_axi_arvalid;
  wire                              sram1_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] sram1_axi_rdata;
  wire [                       1:0] sram1_axi_rresp;
  wire                              sram1_axi_rvalid;
  wire                              sram1_axi_rready;

  wire                              a2x2_switch_sel;
  // verilator lint_off UNUSEDSIGNAL
  wire                              a2x2_sel;
  // verilator lint_on UNUSEDSIGNAL
  wire                              pattern_done;

  // unused
  assign gen_axi_arvalid = 1'b0;
  assign gen_axi_araddr  = 0;
  assign gen_axi_rready  = 1'b0;

  assign vga_axi_awvalid = 1'b0;
  assign vga_axi_awaddr  = 0;
  assign vga_axi_wvalid  = 1'b0;
  assign vga_axi_wdata   = 0;
  assign vga_axi_bready  = 1'b0;
  assign vga_axi_wstrb   = 2'b11;

  assign a2x2_switch_sel = 1'b0;

  axi_2x2 #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) dbuf (
      .axi_clk  (clk),
      .axi_rst_n(~reset),

      // Control interface
      .switch_sel(a2x2_switch_sel),
      .sel       (a2x2_sel),

      // Pattern Gen
      .in0_axi_awaddr (gen_axi_awaddr),
      .in0_axi_awvalid(gen_axi_awvalid),
      .in0_axi_awready(gen_axi_awready),
      .in0_axi_wdata  (gen_axi_wdata),
      .in0_axi_wstrb  (gen_axi_wstrb),
      .in0_axi_wvalid (gen_axi_wvalid),
      .in0_axi_wready (gen_axi_wready),
      .in0_axi_bresp  (gen_axi_bresp),
      .in0_axi_bvalid (gen_axi_bvalid),
      .in0_axi_bready (gen_axi_bready),
      .in0_axi_araddr (gen_axi_araddr),
      .in0_axi_arvalid(gen_axi_arvalid),
      .in0_axi_arready(gen_axi_arready),
      .in0_axi_rdata  (gen_axi_rdata),
      .in0_axi_rresp  (gen_axi_rresp),
      .in0_axi_rvalid (gen_axi_rvalid),
      .in0_axi_rready (gen_axi_rready),

      // VGA
      .in1_axi_awaddr (vga_axi_awaddr),
      .in1_axi_awvalid(vga_axi_awvalid),
      .in1_axi_awready(vga_axi_awready),
      .in1_axi_wdata  (vga_axi_wdata),
      .in1_axi_wstrb  (vga_axi_wstrb),
      .in1_axi_wvalid (vga_axi_wvalid),
      .in1_axi_wready (vga_axi_wready),
      .in1_axi_bresp  (vga_axi_bresp),
      .in1_axi_bvalid (vga_axi_bvalid),
      .in1_axi_bready (vga_axi_bready),
      .in1_axi_araddr (vga_axi_araddr),
      .in1_axi_arvalid(vga_axi_arvalid),
      .in1_axi_arready(vga_axi_arready),
      .in1_axi_rdata  (vga_axi_rdata),
      .in1_axi_rresp  (vga_axi_rresp),
      .in1_axi_rvalid (vga_axi_rvalid),
      .in1_axi_rready (vga_axi_rready),

      // SRAM 0
      .out0_axi_awaddr (sram0_axi_awaddr),
      .out0_axi_awvalid(sram0_axi_awvalid),
      .out0_axi_awready(sram0_axi_awready),
      .out0_axi_wdata  (sram0_axi_wdata),
      .out0_axi_wstrb  (sram0_axi_wstrb),
      .out0_axi_wvalid (sram0_axi_wvalid),
      .out0_axi_wready (sram0_axi_wready),
      .out0_axi_bresp  (sram0_axi_bresp),
      .out0_axi_bvalid (sram0_axi_bvalid),
      .out0_axi_bready (sram0_axi_bready),
      .out0_axi_araddr (sram0_axi_araddr),
      .out0_axi_arvalid(sram0_axi_arvalid),
      .out0_axi_arready(sram0_axi_arready),
      .out0_axi_rdata  (sram0_axi_rdata),
      .out0_axi_rresp  (sram0_axi_rresp),
      .out0_axi_rvalid (sram0_axi_rvalid),
      .out0_axi_rready (sram0_axi_rready),

      // SRAM 1
      .out1_axi_awaddr (sram1_axi_awaddr),
      .out1_axi_awvalid(sram1_axi_awvalid),
      .out1_axi_awready(sram1_axi_awready),
      .out1_axi_wdata  (sram1_axi_wdata),
      .out1_axi_wstrb  (sram1_axi_wstrb),
      .out1_axi_wvalid (sram1_axi_wvalid),
      .out1_axi_wready (sram1_axi_wready),
      .out1_axi_bresp  (sram1_axi_bresp),
      .out1_axi_bvalid (sram1_axi_bvalid),
      .out1_axi_bready (sram1_axi_bready),
      .out1_axi_araddr (sram1_axi_araddr),
      .out1_axi_arvalid(sram1_axi_arvalid),
      .out1_axi_arready(sram1_axi_arready),
      .out1_axi_rdata  (sram1_axi_rdata),
      .out1_axi_rresp  (sram1_axi_rresp),
      .out1_axi_rvalid (sram1_axi_rvalid),
      .out1_axi_rready (sram1_axi_rready)
  );

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl_0 (
      .axi_clk     (clk),
      .axi_resetn  (~reset),
      .axi_awaddr  (sram0_axi_awaddr),
      .axi_awvalid (sram0_axi_awvalid),
      .axi_awready (sram0_axi_awready),
      .axi_wdata   (sram0_axi_wdata),
      .axi_wstrb   (sram0_axi_wstrb),
      .axi_wvalid  (sram0_axi_wvalid),
      .axi_wready  (sram0_axi_wready),
      .axi_bresp   (sram0_axi_bresp),
      .axi_bvalid  (sram0_axi_bvalid),
      .axi_bready  (sram0_axi_bready),
      .axi_araddr  (sram0_axi_araddr),
      .axi_arvalid (sram0_axi_arvalid),
      .axi_arready (sram0_axi_arready),
      .axi_rdata   (sram0_axi_rdata),
      .axi_rresp   (sram0_axi_rresp),
      .axi_rvalid  (sram0_axi_rvalid),
      .axi_rready  (sram0_axi_rready),
      .sram_io_addr(sram0_io_addr),
      .sram_io_data(sram0_io_data),
      .sram_io_we_n(sram0_io_we_n),
      .sram_io_oe_n(sram0_io_oe_n),
      .sram_io_ce_n(sram0_io_ce_n)
  );

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl_1 (
      .axi_clk     (clk),
      .axi_resetn  (~reset),
      .axi_awaddr  (sram1_axi_awaddr),
      .axi_awvalid (sram1_axi_awvalid),
      .axi_awready (sram1_axi_awready),
      .axi_wdata   (sram1_axi_wdata),
      .axi_wstrb   (sram1_axi_wstrb),
      .axi_wvalid  (sram1_axi_wvalid),
      .axi_wready  (sram1_axi_wready),
      .axi_bresp   (sram1_axi_bresp),
      .axi_bvalid  (sram1_axi_bvalid),
      .axi_bready  (sram1_axi_bready),
      .axi_araddr  (sram1_axi_araddr),
      .axi_arvalid (sram1_axi_arvalid),
      .axi_arready (sram1_axi_arready),
      .axi_rdata   (sram1_axi_rdata),
      .axi_rresp   (sram1_axi_rresp),
      .axi_rvalid  (sram1_axi_rvalid),
      .axi_rready  (sram1_axi_rready),
      .sram_io_addr(sram1_io_addr),
      .sram_io_data(sram1_io_data),
      .sram_io_we_n(sram1_io_we_n),
      .sram_io_oe_n(sram1_io_oe_n),
      .sram_io_ce_n(sram1_io_ce_n)
  );

  vga_sram_pattern_generator #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) pattern (
      .clk         (clk),
      .reset       (reset),
      .pattern_done(pattern_done),

      .axi_awaddr (gen_axi_awaddr),
      .axi_awvalid(gen_axi_awvalid),
      .axi_awready(gen_axi_awready),
      .axi_wdata  (gen_axi_wdata),
      .axi_wstrb  (gen_axi_wstrb),
      .axi_wvalid (gen_axi_wvalid),
      .axi_wready (gen_axi_wready),
      .axi_bresp  (gen_axi_bresp),
      .axi_bvalid (gen_axi_bvalid),
      .axi_bready (gen_axi_bready)
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

  // detect_rising rising_pattern_done (
  //     .clk     (clk),
  //     .signal  (pattern_done),
  //     .detected(a2x2_switch_sel)
  // );

  vga_sram_pixel_stream #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) pixel_stream (
      .clk   (clk),
      .reset (reset),
      .enable(pattern_done & !fifo_almost_full),

      .axi_araddr (vga_axi_araddr),
      .axi_arvalid(vga_axi_arvalid),
      .axi_arready(vga_axi_arready),
      .axi_rdata  (vga_axi_rdata),
      .axi_rresp  (vga_axi_rresp),
      .axi_rvalid (vga_axi_rvalid),
      .axi_rready (vga_axi_rready),

      .vsync(sram_vga_vsync),
      .hsync(sram_vga_hsync),
      .red  (sram_vga_red),
      .green(sram_vga_green),
      .blue (sram_vga_blue),
      .valid(sram_vga_data_valid)
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
