`include "testing.sv"

`include "axi_sram_controller.sv"
`include "sram_model.sv"
`include "vga_fb_pixel_stream_striped.sv"

// verilator lint_off UNUSEDSIGNAL
module vga_fb_pixel_stream_striped_tb;
  localparam NUM_S = 2;
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

  logic                                          clk;
  logic                                          reset;

  // stream signals
  logic                                          pixel_stream_enable;
  logic                                          pixel_stream_valid;

  // sync signals
  logic                                          pixel_stream_vsync;
  logic                                          pixel_stream_hsync;
  logic                                          pixel_stream_visible;

  // color
  logic [    PIXEL_BITS-1:0]                     pixel_stream_color;

  // pixel addr
  logic [AXI_ADDR_WIDTH-1:0]                     pixel_stream_addr;

  // FB AXI
  logic [         NUM_S-1:0][AXI_ADDR_WIDTH-1:0] fb_axi_awaddr;
  logic [         NUM_S-1:0]                     fb_axi_awvalid;
  logic [         NUM_S-1:0]                     fb_axi_awready;
  logic [         NUM_S-1:0][AXI_DATA_WIDTH-1:0] fb_axi_wdata;
  logic [         NUM_S-1:0][AXI_STRB_WIDTH-1:0] fb_axi_wstrb;
  logic [         NUM_S-1:0]                     fb_axi_wvalid;
  logic [         NUM_S-1:0]                     fb_axi_wready;
  logic [         NUM_S-1:0][               1:0] fb_axi_bresp;
  logic [         NUM_S-1:0]                     fb_axi_bvalid;
  logic [         NUM_S-1:0]                     fb_axi_bready;
  logic [         NUM_S-1:0][AXI_ADDR_WIDTH-1:0] fb_axi_araddr;
  logic [         NUM_S-1:0]                     fb_axi_arvalid;
  logic [         NUM_S-1:0]                     fb_axi_arready;
  logic [         NUM_S-1:0][AXI_DATA_WIDTH-1:0] fb_axi_rdata;
  logic [         NUM_S-1:0][               1:0] fb_axi_rresp;
  logic [         NUM_S-1:0]                     fb_axi_rvalid;
  logic [         NUM_S-1:0]                     fb_axi_rready;


  // SRAM 0
  logic [         NUM_S-1:0][AXI_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [         NUM_S-1:0][AXI_DATA_WIDTH-1:0] sram_io_data;
  logic [         NUM_S-1:0]                     sram_io_we_n;
  logic [         NUM_S-1:0]                     sram_io_oe_n;
  logic [         NUM_S-1:0]                     sram_io_ce_n;

  vga_fb_pixel_stream_striped #(
      .NUM_S     (NUM_S),
      .PIXEL_BITS(PIXEL_BITS),

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

      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) uut (
      .clk  (clk),
      .reset(reset),

      // stream signals
      .enable(pixel_stream_enable),
      .valid (pixel_stream_valid),

      // sync signals
      .vsync  (pixel_stream_vsync),
      .hsync  (pixel_stream_hsync),
      .visible(pixel_stream_visible),

      // color/addr
      .color(pixel_stream_color),
      .addr (pixel_stream_addr),

      .fb_axi_araddr (fb_axi_araddr),
      .fb_axi_arvalid(fb_axi_arvalid),
      .fb_axi_arready(fb_axi_arready),
      .fb_axi_rdata  (fb_axi_rdata),
      .fb_axi_rready (fb_axi_rready),
      .fb_axi_rresp  (fb_axi_rresp),
      .fb_axi_rvalid (fb_axi_rvalid)
  );

  for (genvar i = 0; i < NUM_S; i++) begin : gen_s_modules
    axi_sram_controller #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi_sram_ctrl_i (
        .axi_clk     (clk),
        .axi_resetn  (~reset),
        .axi_awaddr  (fb_axi_awaddr[i]),
        .axi_awvalid (fb_axi_awvalid[i]),
        .axi_awready (fb_axi_awready[i]),
        .axi_wdata   (fb_axi_wdata[i]),
        .axi_wstrb   (fb_axi_wstrb[i]),
        .axi_wvalid  (fb_axi_wvalid[i]),
        .axi_wready  (fb_axi_wready[i]),
        .axi_bresp   (fb_axi_bresp[i]),
        .axi_bvalid  (fb_axi_bvalid[i]),
        .axi_bready  (fb_axi_bready[i]),
        .axi_araddr  (fb_axi_araddr[i]),
        .axi_arvalid (fb_axi_arvalid[i]),
        .axi_arready (fb_axi_arready[i]),
        .axi_rdata   (fb_axi_rdata[i]),
        .axi_rresp   (fb_axi_rresp[i]),
        .axi_rvalid  (fb_axi_rvalid[i]),
        .axi_rready  (fb_axi_rready[i]),
        .sram_io_addr(sram_io_addr[i]),
        .sram_io_data(sram_io_data[i]),
        .sram_io_we_n(sram_io_we_n[i]),
        .sram_io_oe_n(sram_io_oe_n[i]),
        .sram_io_ce_n(sram_io_ce_n[i])
    );

    sram_model #(
        .ADDR_BITS                (AXI_ADDR_WIDTH),
        .DATA_BITS                (AXI_DATA_WIDTH),
        .UNINITIALIZED_READS_FATAL(0)
    ) sram_i (
        .we_n   (sram_io_we_n[i]),
        .oe_n   (sram_io_oe_n[i]),
        .ce_n   (sram_io_ce_n[i]),
        .addr   (sram_io_addr[i]),
        .data_io(sram_io_data[i])
    );
  end

  // verilator lint_off WIDTHEXPAND
  `TEST_SETUP(vga_fb_pixel_stream_striped_tb);
  logic [               8:0] test_line;

  logic [  PIXEL_X_BITS-1:0] pixel_x;
  logic [  PIXEL_Y_BITS-1:0] pixel_y;

  logic [AXI_ADDR_WIDTH-1:0] pixel_addr;
  logic [    PIXEL_BITS-1:0] pixel_bits;

  assign pixel_bits = pixel_stream_color;

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

      fb_axi_awaddr       = '0;
      fb_axi_awvalid      = '0;
      fb_axi_wdata        = '0;
      fb_axi_wstrb        = '0;
      fb_axi_wvalid       = '0;
      fb_axi_bready       = '0;

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
        `ASSERT(pixel_stream_visible);
        `ASSERT_EQ(pixel_bits, pixel_addr);
      end else begin
        `ASSERT(!pixel_stream_visible);
        `ASSERT_EQ(pixel_bits, '0);
      end
    end
  end

  // pixel_addr
  always_comb begin
    pixel_addr = pixel_y * H_VISIBLE + pixel_x;
  end

  always @(posedge clk) begin
    if (pixel_stream_valid) begin
      `ASSERT_EQ(pixel_stream_addr, pixel_addr);
    end
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
  // verilator lint_on WIDTHEXPAND

endmodule
// verilator lint_on UNUSEDSIGNAL
