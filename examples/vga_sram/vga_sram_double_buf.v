`ifndef VGA_SRAM_DOUBLE_BUF_V
`define VGA_SRAM_DOUBLE_BUF_V

`include "directives.v"

// Quick poc of the how double buffering will work using
// the axi 2x2.

`include "axi_sram_dbuf_controller.v"
`include "cdc_fifo.v"
`include "detect_falling.v"
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
  wire                              gen_axi_bvalid;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] gen_axi_wstrb;
  // verilator lint_off UNUSEDSIGNAL
  wire [                       1:0] gen_axi_bresp;
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
  // verilator lint_off UNUSEDSIGNAL
  wire [                       1:0] vga_axi_rresp;
  // verilator lint_on UNUSEDSIGNAL

  // control signals
  wire                              mem_switch;
  wire                              pattern_done;

  axi_sram_dbuf_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) axi_sram_dbuf_controller_inst (
      // core signals
      .clk  (clk),
      .reset(reset),

      // switch producer/consumer to alternate sram
      .switch(mem_switch),

      // producer interface
      .prod_axi_awaddr (gen_axi_awaddr),
      .prod_axi_awvalid(gen_axi_awvalid),
      .prod_axi_awready(gen_axi_awready),
      .prod_axi_wdata  (gen_axi_wdata),
      .prod_axi_wvalid (gen_axi_wvalid),
      .prod_axi_wready (gen_axi_wready),
      .prod_axi_wstrb  (gen_axi_wstrb),
      .prod_axi_bready (gen_axi_bready),
      .prod_axi_bvalid (gen_axi_bvalid),
      .prod_axi_bresp  (gen_axi_bresp),

      // consumer interface
      .cons_axi_araddr (vga_axi_araddr),
      .cons_axi_arvalid(vga_axi_arvalid),
      .cons_axi_arready(vga_axi_arready),
      .cons_axi_rdata  (vga_axi_rdata),
      .cons_axi_rvalid (vga_axi_rvalid),
      .cons_axi_rready (vga_axi_rready),
      .cons_axi_rresp  (vga_axi_rresp),

      // sram0 controller to io pins
      .sram0_io_addr(sram0_io_addr),
      .sram0_io_data(sram0_io_data),
      .sram0_io_we_n(sram0_io_we_n),
      .sram0_io_oe_n(sram0_io_oe_n),
      .sram0_io_ce_n(sram0_io_ce_n),

      // sram1 controller to io pins
      .sram1_io_addr(sram1_io_addr),
      .sram1_io_data(sram1_io_data),
      .sram1_io_we_n(sram1_io_we_n),
      .sram1_io_oe_n(sram1_io_oe_n),
      .sram1_io_ce_n(sram1_io_ce_n)
  );

  vga_sram_pattern_generator #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) pattern (
      .clk         (clk),
      .reset       (reset | mem_switch),
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

  // signals as they come from the sram stream
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

  // The first switch is on first_pattern_done since the pixel generator
  // is not running before that. Once it's running, we trigger when
  // we are in the vertical blanking. (We could expose a frame done signal, as
  // it's actually a little ahead of vsync, but this is fine.
  wire posedge_first_pattern_done;
  detect_rising rising_pattern_done (
      .clk     (clk),
      .signal  (first_pattern_done),
      .detected(posedge_first_pattern_done)
  );

  wire negedge_sram_vga_vsync;
  detect_falling falling_sram_vga_vsync (
      .clk     (clk),
      .signal  (sram_vga_vsync),
      .detected(negedge_sram_vga_vsync)
  );

  assign mem_switch = (posedge_first_pattern_done | negedge_sram_vga_vsync);

  reg first_pattern_done = 1'b0;
  always @(posedge clk) begin
    if (reset) begin
      first_pattern_done <= 1'b0;
    end else begin
      if (!first_pattern_done) begin
        first_pattern_done <= pattern_done;
      end
    end
  end

  vga_sram_pixel_stream #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) pixel_stream (
      .clk   (clk),
      .reset (reset),
      .enable(first_pattern_done & !fifo_almost_full),

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
      .DATA_WIDTH     (VGA_DATA_WIDTH),
      .ADDR_SIZE      (4),
      .ALMOST_FULL_BUF(8)
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
