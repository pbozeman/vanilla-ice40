`include "testing.sv"

`include "axi_sram_controller.sv"
`include "sram_model.sv"
`include "vga_fb_pixel_stream.sv"

// verilator lint_off UNUSEDSIGNAL
module vga_fb_pixel_stream_tb;
  localparam AXI_ADDR_WIDTH = 10;
  localparam AXI_DATA_WIDTH = 16;
  localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8;

  // Reduce the size so testing doesn't take an eternity.

  // Horizontal Timing
  localparam H_VISIBLE = 16;
  localparam H_FRONT_PORCH = 2;
  localparam H_SYNC_PULSE = 3;
  localparam H_BACK_PORCH = 2;
  localparam H_WHOLE_LINE = 23;

  // Vertical Timing
  localparam V_VISIBLE = 8;
  localparam V_FRONT_PORCH = 2;
  localparam V_SYNC_PULSE = 3;
  localparam V_BACK_PORCH = 3;
  localparam V_WHOLE_FRAME = 16;

  localparam PIXEL_BITS = 12;
  localparam PIXEL_X_BITS = $clog2(H_WHOLE_LINE);
  localparam PIXEL_Y_BITS = $clog2(V_WHOLE_FRAME);
  localparam COLOR_BITS = PIXEL_BITS / 3;

  logic                      clk;
  logic                      reset;

  // stream signals
  logic                      pixel_stream_enable;
  logic                      pixel_stream_valid;

  // sync signals
  logic                      pixel_stream_vsync;
  logic                      pixel_stream_hsync;

  // color
  logic [    COLOR_BITS-1:0] pixel_stream_red;
  logic [    COLOR_BITS-1:0] pixel_stream_grn;
  logic [    COLOR_BITS-1:0] pixel_stream_blu;

  // SRAM AXI
  logic [AXI_ADDR_WIDTH-1:0] sram0_axi_awaddr;
  logic                      sram0_axi_awvalid;
  logic                      sram0_axi_awready;
  logic [AXI_DATA_WIDTH-1:0] sram0_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] sram0_axi_wstrb;
  logic                      sram0_axi_wvalid;
  logic                      sram0_axi_wready;
  logic [               1:0] sram0_axi_bresp;
  logic                      sram0_axi_bvalid;
  logic                      sram0_axi_bready;
  logic [AXI_ADDR_WIDTH-1:0] sram0_axi_araddr;
  logic                      sram0_axi_arvalid;
  logic                      sram0_axi_arready;
  logic [AXI_DATA_WIDTH-1:0] sram0_axi_rdata;
  logic [               1:0] sram0_axi_rresp;
  logic                      sram0_axi_rvalid;
  logic                      sram0_axi_rready;


  // SRAM 0
  logic [AXI_ADDR_WIDTH-1:0] sram0_io_addr;
  wire  [AXI_DATA_WIDTH-1:0] sram0_io_data;
  logic                      sram0_io_we_n;
  logic                      sram0_io_oe_n;
  logic                      sram0_io_ce_n;

  vga_fb_pixel_stream #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),

      .H_VISIBLE    (H_VISIBLE),
      .H_FRONT_PORCH(H_FRONT_PORCH),
      .H_SYNC_PULSE (H_SYNC_PULSE),
      .H_BACK_PORCH (H_BACK_PORCH),
      .H_WHOLE_LINE (H_WHOLE_LINE),

      .V_VISIBLE    (V_VISIBLE),
      .V_FRONT_PORCH(V_FRONT_PORCH),
      .V_SYNC_PULSE (V_SYNC_PULSE),
      .V_BACK_PORCH (V_BACK_PORCH),
      .V_WHOLE_FRAME(V_WHOLE_FRAME),

      .PIXEL_BITS(PIXEL_BITS)
  ) uut (
      .clk  (clk),
      .reset(reset),

      // stream signals
      .enable(pixel_stream_enable),
      .valid (pixel_stream_valid),

      // sync signals
      .vsync(pixel_stream_vsync),
      .hsync(pixel_stream_hsync),

      // color
      .red(pixel_stream_red),
      .grn(pixel_stream_grn),
      .blu(pixel_stream_blu),

      .sram_axi_araddr (sram0_axi_araddr),
      .sram_axi_arvalid(sram0_axi_arvalid),
      .sram_axi_arready(sram0_axi_arready),
      .sram_axi_rdata  (sram0_axi_rdata),
      .sram_axi_rready (sram0_axi_rready),
      .sram_axi_rresp  (sram0_axi_rresp),
      .sram_axi_rvalid (sram0_axi_rvalid)
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

  sram_model #(
      .ADDR_BITS                (AXI_ADDR_WIDTH),
      .DATA_BITS                (AXI_DATA_WIDTH),
      .UNINITIALIZED_READS_FATAL(0)
  ) sram_0 (
      .we_n   (sram0_io_we_n),
      .oe_n   (sram0_io_oe_n),
      .ce_n   (sram0_io_ce_n),
      .addr   (sram0_io_addr),
      .data_io(sram0_io_data)
  );

  `TEST_SETUP(vga_fb_pixel_stream_tb);
  logic [               8:0] test_line;

  logic [  PIXEL_X_BITS-1:0] pixel_x;
  logic [  PIXEL_Y_BITS-1:0] pixel_y;

  logic [AXI_ADDR_WIDTH-1:0] pixel_addr;
  logic [    PIXEL_BITS-1:0] pixel_bits;

  assign pixel_bits = {pixel_stream_red, pixel_stream_grn, pixel_stream_blu};

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  task reset_test;
    begin
      @(posedge clk);
      reset = 1'b1;
      @(posedge clk);

      pixel_stream_enable = 1'b0;

      sram0_axi_awaddr    = '0;
      sram0_axi_awvalid   = 1'b0;
      sram0_axi_wdata     = '0;
      sram0_axi_wstrb     = '0;
      sram0_axi_wvalid    = 1'b0;
      sram0_axi_bready    = 1'b0;

      pixel_x             = '0;
      pixel_y             = '0;

      @(posedge clk);
      reset = 1'b0;
      @(posedge clk);
    end
  endtask

  // invariants
  localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
  localparam H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;

  localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
  localparam V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;

  // hsync
  always @(posedge clk) begin
    if (pixel_stream_valid) begin
      `ASSERT_EQ(pixel_stream_hsync,
                 !(pixel_x >= H_SYNC_START && pixel_x < H_SYNC_END));
    end
  end

  // vsync
  always @(posedge clk) begin
    if (pixel_stream_valid) begin
      `ASSERT_EQ(pixel_stream_vsync,
                 !(pixel_y >= V_SYNC_START && pixel_y < V_SYNC_END));
    end
  end

  // data
  always @(posedge clk) begin
    if (pixel_stream_valid) begin
      if (pixel_x < H_VISIBLE && pixel_y < V_VISIBLE) begin
        `ASSERT_EQ(pixel_bits, pixel_addr);
      end else begin
        `ASSERT_EQ(pixel_bits, '0);
      end
    end
  end

  // pixel_addr
  always_comb begin
    pixel_addr = pixel_y * H_VISIBLE + pixel_x;
  end

  // pixel x/y
  always @(posedge clk) begin
    if (pixel_stream_valid) begin
      if (pixel_x < H_WHOLE_LINE - 1) begin
        pixel_x <= pixel_x + 1;
      end else begin
        pixel_x <= '0;
        pixel_y <= pixel_y + 1;
      end
    end
  end

  task test_basic;
    begin
      test_line = `__LINE__;
      reset_test();

      pixel_stream_enable = 1'b1;

      // 3 frames
      repeat (3 * H_WHOLE_LINE * V_WHOLE_FRAME) begin
        @(posedge clk);
      end
    end
  endtask

  initial begin
    test_basic();

    $finish;
  end

endmodule
// verilator lint_on UNUSEDSIGNAL
