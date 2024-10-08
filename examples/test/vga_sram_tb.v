
`include "testing.v"
`include "sram_model.v"

`include "axi_sram_controller.v"
`include "vga_sram_pattern_generator.v"
`include "vga_sram_pixel_stream.v"

// This is not intended to be a full test. This is just to see some wave forms
// in the simulator.

module vga_sram_tb;

  parameter AXI_ADDR_WIDTH = 20;
  parameter AXI_DATA_WIDTH = 16;

  reg                               pixel_clk;
  reg                               clk;
  reg                               reset;

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

  // SRAM Interface
  wire [        AXI_ADDR_WIDTH-1:0] sram_addr;
  wire [        AXI_DATA_WIDTH-1:0] sram_data;
  wire                              sram_we_n;
  wire                              sram_oe_n;
  wire                              sram_ce_n;

  wire                              pattern_done;
  wire                              vsync;
  wire                              hsync;
  wire [                       3:0] red;
  wire [                       3:0] green;
  wire [                       3:0] blue;

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

      .vsync(vsync),
      .hsync(hsync),
      .red  (red),
      .green(green),
      .blue (blue)
  );

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


  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram (
      .we_n(sram_we_n),
      .oe_n(sram_oe_n),
      .ce_n(sram_ce_n),
      .addr(sram_addr),
      .data_io(sram_data)
  );

  // 100mhz main clock (also axi clock)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 25mhz pixel clock
  initial begin
    pixel_clk = 0;
    forever #20 pixel_clk = ~pixel_clk;
  end

  `TEST_SETUP(vga_sram_tb);

  // Test procedure
  initial begin
    reset = 1;
    repeat (10) @(posedge clk);
    reset = 0;

    repeat (3 * 640 * 480) @(posedge clk);
    $finish;
  end

endmodule
