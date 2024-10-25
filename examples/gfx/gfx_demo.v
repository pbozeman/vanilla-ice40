`ifndef GFX_DEMO_V
`define GFX_DEMO_V


`include "directives.v"

`include "axi_sram_dbuf_controller.v"
`include "fb_writer.v"
`include "gfx_test_pattern.v"

module gfx_demo #(
    parameter VGA_WIDTH      = 640,
    parameter VGA_HEIGHT     = 480,
    parameter PIXEL_BITS     = 12,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input wire clk,
    input wire reset,

    output wire [AXI_ADDR_WIDTH-1:0] addr,
    output wire [    PIXEL_BITS-1:0] color,

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
    output wire                      sram1_io_ce_n
);
  localparam FB_X_BITS = $clog2(VGA_WIDTH);
  localparam FB_Y_BITS = $clog2(VGA_HEIGHT);

  //
  // gfx axi writter
  //
  wire [        AXI_ADDR_WIDTH-1:0] gfx_axi_awaddr;
  wire                              gfx_axi_awvalid;
  wire                              gfx_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] gfx_axi_wdata;
  wire                              gfx_axi_wvalid;
  wire                              gfx_axi_wready;
  wire                              gfx_axi_bready;
  wire                              gfx_axi_bvalid;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] gfx_axi_wstrb;
  wire [                       1:0] gfx_axi_bresp;

  //
  // disp axi reader
  //
  wire [        AXI_ADDR_WIDTH-1:0] disp_axi_araddr;
  wire                              disp_axi_arvalid;
  wire                              disp_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] disp_axi_rdata;
  wire                              disp_axi_rvalid;
  wire                              disp_axi_rready;
  wire [                       1:0] disp_axi_rresp;

  wire                              mem_switch;
  assign mem_switch = 1'b0;

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
      .prod_axi_awaddr (gfx_axi_awaddr),
      .prod_axi_awvalid(gfx_axi_awvalid),
      .prod_axi_awready(gfx_axi_awready),
      .prod_axi_wdata  (gfx_axi_wdata),
      .prod_axi_wvalid (gfx_axi_wvalid),
      .prod_axi_wready (gfx_axi_wready),
      .prod_axi_wstrb  (gfx_axi_wstrb),
      .prod_axi_bready (gfx_axi_bready),
      .prod_axi_bvalid (gfx_axi_bvalid),
      .prod_axi_bresp  (gfx_axi_bresp),

      // consumer interface
      .cons_axi_araddr (disp_axi_araddr),
      .cons_axi_arvalid(disp_axi_arvalid),
      .cons_axi_arready(disp_axi_arready),
      .cons_axi_rdata  (disp_axi_rdata),
      .cons_axi_rvalid (disp_axi_rvalid),
      .cons_axi_rready (disp_axi_rready),
      .cons_axi_rresp  (disp_axi_rresp),

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

  // gfx signals
  wire [ FB_X_BITS-1:0] gfx_x;
  wire [ FB_Y_BITS-1:0] gfx_y;
  wire [PIXEL_BITS-1:0] gfx_color;
  wire                  gfx_inc;
  wire                  gfx_last;
  wire                  gfx_valid;

  // TODO: rename u_pat
  gfx_test_pattern u_pat (
      .clk  (clk),
      .reset(reset),
      .inc  (gfx_inc),
      .x    (gfx_x),
      .y    (gfx_y),
      .color(gfx_color),
      .valid(gfx_valid),
      .last (gfx_last)
  );

  // fb writer axi flow control signals
  reg                       fb_axi_tvalid;
  wire                      fb_axi_tready;

  // and the data that goes with them
  reg  [AXI_ADDR_WIDTH-1:0] fb_addr;
  reg  [    PIXEL_BITS-1:0] fb_color;

  fb_writer #(
      .PIXEL_BITS    (PIXEL_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) fb_writer_inst (
      .clk  (clk),
      .reset(reset),

      .axi_tvalid(fb_axi_tvalid),
      .axi_tready(fb_axi_tready),

      .addr (fb_addr),
      .color(fb_color),

      .sram_axi_awaddr (gfx_axi_awaddr),
      .sram_axi_awvalid(gfx_axi_awvalid),
      .sram_axi_awready(gfx_axi_awready),
      .sram_axi_wdata  (gfx_axi_wdata),
      .sram_axi_wstrb  (gfx_axi_wstrb),
      .sram_axi_wvalid (gfx_axi_wvalid),
      .sram_axi_wready (gfx_axi_wready),
      .sram_axi_bvalid (gfx_axi_bvalid),
      .sram_axi_bready (gfx_axi_bready),
      .sram_axi_bresp  (gfx_axi_bresp)
  );

  wire [AXI_ADDR_WIDTH-1:0] gfx_addr;
  assign gfx_inc  = (fb_axi_tready & fb_axi_tvalid);
  assign gfx_addr = (VGA_WIDTH * gfx_y + gfx_x);

  // fb writer data
  always @(posedge clk) begin
    if (reset) begin
      fb_axi_tvalid <= 1'b0;
    end else begin
      if (gfx_valid) begin
        fb_addr       <= gfx_addr;
        fb_color      <= gfx_color;
        fb_axi_tvalid <= 1'b1;
      end else begin
        if (fb_axi_tvalid & fb_axi_tready) begin
          fb_axi_tvalid <= 1'b0;
        end
      end
    end
  end

  assign addr  = fb_addr;
  assign color = fb_color;

endmodule

`endif
