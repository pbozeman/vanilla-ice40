`include "testing.sv"

`include "gfx_vga_fade.sv"
`include "sram_model.sv"
`include "sticky_bit.sv"

// verilator lint_off UNUSEDSIGNAL
module gfx_vga_fade_tb;
  localparam AXI_ADDR_WIDTH = 10;
  localparam AXI_DATA_WIDTH = 16;

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
  localparam FB_X_BITS = $clog2(H_VISIBLE);
  localparam FB_Y_BITS = $clog2(V_VISIBLE);
  localparam PIXEL_X_BITS = $clog2(H_WHOLE_LINE);
  localparam PIXEL_Y_BITS = $clog2(V_WHOLE_FRAME);
  localparam COLOR_BITS = PIXEL_BITS / 3;

  logic                      clk;
  logic                      pixel_clk;
  logic                      reset;

  // gfx signals
  logic [     FB_X_BITS-1:0] gfx_x;
  logic [     FB_Y_BITS-1:0] gfx_y;
  logic [    PIXEL_BITS-1:0] gfx_color;
  logic                      gfx_pready;
  logic                      gfx_pvalid;
  logic                      gfx_vsync;

  // vga signals
  logic                      vga_enable;

  // sync signals
  logic                      vga_vsync;
  logic                      vga_hsync;

  // color
  logic [    COLOR_BITS-1:0] vga_red;
  logic [    COLOR_BITS-1:0] vga_grn;
  logic [    COLOR_BITS-1:0] vga_blu;

  // SRAM 0
  logic [AXI_ADDR_WIDTH-1:0] sram0_io_addr;
  wire  [AXI_DATA_WIDTH-1:0] sram0_io_data;
  logic                      sram0_io_we_n;
  logic                      sram0_io_oe_n;
  logic                      sram0_io_ce_n;

  gfx_vga_fade #(
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
      .clk      (clk),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .gfx_x    (gfx_x),
      .gfx_y    (gfx_y),
      .gfx_color(gfx_color),
      .gfx_valid(gfx_pvalid),
      .gfx_ready(gfx_pready),
      .gfx_vsync(gfx_vsync),

      .vga_enable(vga_enable),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),

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

  `TEST_SETUP(gfx_vga_fade_tb);

  logic [8:0] test_line;

  // 100mhz main clock (also axi clock)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // mode specific pixel clock
  initial begin
    pixel_clk = 0;
    forever #`VGA_MODE_TB_PIXEL_CLK pixel_clk = ~pixel_clk;
  end

  logic [  PIXEL_X_BITS-1:0] pixel_x;
  logic [  PIXEL_Y_BITS-1:0] pixel_y;

  logic [AXI_ADDR_WIDTH-1:0] pixel_addr;
  logic [    PIXEL_BITS-1:0] pixel_bits;
  logic                      checks_en;

  assign pixel_bits = {vga_red, vga_grn, vga_blu};

  // invariants
  localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
  localparam H_SYNC_END = H_SYNC_START + H_SYNC_PULSE;

  localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
  localparam V_SYNC_END = V_SYNC_START + V_SYNC_PULSE;

  //
  // main clock invariants
  //
  always @(posedge clk) begin
    // We are running faster than the pixel clock, but we should not
    // overrun the fifo.
    `ASSERT(!uut.fifo.w_full);
  end

  //
  // pixel clock invariants
  //

  // checks are enabled once the first pixel makes it through the pipeline
  sticky_bit sticky_checks_en (
      .clk  (pixel_clk),
      .reset(reset),
      .clear(1'b0),
      .in   (!uut.fifo.r_empty),
      .out  (checks_en)
  );

  always @(posedge pixel_clk) begin
    // This would indicate that there as a bubble somewhere (i.e. with memory
    // contention between the gfx writer and the display stream) and a pixel
    // wasn't ready when we needed one.
    if (checks_en) begin
      `ASSERT(!uut.fifo.r_empty);
    end
  end

  // hsync
  always @(posedge pixel_clk) begin
    if (checks_en) begin
      `ASSERT_EQ(vga_hsync, !(pixel_x >= H_SYNC_START && pixel_x < H_SYNC_END));
    end
  end

  // vsync
  always @(posedge pixel_clk) begin
    if (checks_en) begin
      `ASSERT_EQ(vga_vsync, !(pixel_y >= V_SYNC_START && pixel_y < V_SYNC_END));
    end
  end

  // data
  always @(posedge pixel_clk) begin
    if (checks_en) begin
      `ASSERT(!uut.fifo.r_empty);
      if (pixel_x < H_VISIBLE && pixel_y < V_VISIBLE) begin
        // TODO: test fading pixels
        if (pixel_bits != 0) begin
          `ASSERT_EQ(pixel_bits, pixel_addr);
        end
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
  always @(posedge pixel_clk) begin
    if (checks_en) begin
      if (pixel_x < H_WHOLE_LINE - 1) begin
        pixel_x <= pixel_x + 1;
      end else begin
        pixel_x <= '0;
        pixel_y <= pixel_y + 1;
      end
    end
  end

  //
  // Linear write block
  //
  logic                  wl_en;

  logic [ FB_X_BITS-1:0] gfx_wl_x;
  logic [ FB_Y_BITS-1:0] gfx_wl_y;
  logic [PIXEL_BITS-1:0] gfx_wl_color;
  logic                  gfx_wl_pready;
  logic                  gfx_wl_pvalid;

  assign gfx_wl_pready = gfx_pready;

  always_comb begin
    gfx_wl_color = gfx_wl_y * H_VISIBLE + gfx_wl_x;
  end

  always @(posedge clk) begin
    if (reset) begin
      gfx_wl_x      <= '0;
      gfx_wl_y      <= '0;
      gfx_wl_pvalid <= 1'b0;
    end else if (wl_en) begin
      if (!gfx_wl_pvalid || gfx_wl_pready) begin
        gfx_wl_pvalid <= 1'b1;

        if (gfx_pready) begin
          // Increment coordinates
          if (gfx_wl_x < H_VISIBLE - 1) begin
            gfx_wl_x <= gfx_wl_x + 1;
          end else begin
            gfx_wl_x <= '0;
            if (gfx_wl_y < V_VISIBLE - 1) begin
              gfx_wl_y <= gfx_wl_y + 1;
            end else begin
              gfx_wl_y <= '0;
            end
          end
        end
      end
    end
  end

  //
  // Even write block
  //
  logic                  we_en;

  logic [ FB_X_BITS-1:0] gfx_we_x;
  logic [ FB_Y_BITS-1:0] gfx_we_y;
  logic [PIXEL_BITS-1:0] gfx_we_color;
  logic                  gfx_we_pready;
  logic                  gfx_we_pvalid;

  assign gfx_we_pready = gfx_pready;

  always_comb begin
    gfx_we_color = gfx_we_y * H_VISIBLE + gfx_we_x;
  end

  always @(posedge clk) begin
    if (reset) begin
      gfx_we_x      <= 0;
      gfx_we_y      <= 0;
      gfx_we_pvalid <= 1'b0;
    end else if (we_en) begin
      if (!gfx_we_pvalid || gfx_we_pready) begin
        gfx_we_pvalid <= 1'b1;

        if (gfx_we_pready) begin
          // Increment coordinates
          if (gfx_we_x < H_VISIBLE - 1) begin
            gfx_we_x <= gfx_we_x + 2;
          end else begin
            gfx_we_x <= '0;
            if (gfx_we_y < V_VISIBLE - 1) begin
              gfx_we_y <= gfx_we_y + 1;
            end else begin
              gfx_we_y <= '0;
            end
          end
        end
      end
    end
  end

  //
  // Random write block
  //
  logic                  wr_en;

  logic [ FB_X_BITS-1:0] gfx_wr_x;
  logic [ FB_Y_BITS-1:0] gfx_wr_y;
  logic [PIXEL_BITS-1:0] gfx_wr_color;
  logic                  gfx_wr_pready;
  logic                  gfx_wr_pvalid;

  assign gfx_wr_pready = gfx_pready;

  // Color matches the pattern of uninitialized SRAM for checking
  always_comb begin
    gfx_wr_color = gfx_wr_y * H_VISIBLE + gfx_wr_x;
  end

  // Generate random coordinates on each write
  always @(posedge clk) begin
    if (reset) begin
      gfx_wr_x      <= '0;
      gfx_wr_y      <= '0;
      gfx_wr_pvalid <= 1'b0;
    end else if (wr_en) begin
      if (!gfx_wr_pvalid || gfx_wr_pready) begin
        gfx_wr_pvalid <= 1'b1;

        if (gfx_wr_pready) begin
          // Random coordinates within visible area
          gfx_wr_x <= $urandom_range(0, H_VISIBLE - 1);
          gfx_wr_y <= $urandom_range(0, V_VISIBLE - 1);
        end
      end
    end
  end

  //
  // gfx mux
  //
  always @(posedge clk) begin
    // a safeguard against bad testing.
    // only 1 should be active.
    `ASSERT(!(wl_en && we_en && wr_en));
  end

  always_comb begin
    gfx_x      = '0;
    gfx_y      = '0;
    gfx_pvalid = 1'b0;
    gfx_color  = '0;

    if (wl_en) begin
      gfx_x      = gfx_wl_x;
      gfx_y      = gfx_wl_y;
      gfx_pvalid = gfx_wl_pvalid;
      gfx_color  = gfx_wl_color;
    end

    if (we_en) begin
      gfx_x      = gfx_we_x;
      gfx_y      = gfx_we_y;
      gfx_pvalid = gfx_we_pvalid;
      gfx_color  = gfx_we_color;
    end

    if (wr_en) begin
      gfx_x      = gfx_wr_x;
      gfx_y      = gfx_wr_y;
      gfx_pvalid = gfx_wr_pvalid;
      gfx_color  = gfx_wr_color;
    end
  end

  task reset_test;
    begin
      vga_enable = 1'b0;
      reset      = 1'b1;

      // it takes a few cycles for the cdc fifos to reset
      repeat (2) @(posedge pixel_clk);

      pixel_x = '0;
      pixel_y = '0;

      wl_en   = 1'b0;
      we_en   = 1'b0;

      @(posedge pixel_clk);
      reset = 1'b0;
      @(posedge pixel_clk);
    end
  endtask

  task test_idle;
    begin
      test_line = `__LINE__;
      reset_test();

      vga_enable = 1'b1;

      // 3 frames
      repeat (3 * H_WHOLE_LINE * V_WHOLE_FRAME) begin
        @(posedge pixel_clk);
      end
    end
  endtask

  task test_linear_write;
    begin
      test_line = `__LINE__;
      reset_test();

      vga_enable = 1'b1;
      wl_en      = 1'b1;

      // 3 frames
      repeat (3 * H_WHOLE_LINE * V_WHOLE_FRAME) begin
        @(posedge pixel_clk);
      end
    end
  endtask

  task test_even_write;
    begin
      test_line = `__LINE__;
      reset_test();

      vga_enable = 1'b1;
      we_en      = 1'b1;

      // 3 frames
      repeat (3 * H_WHOLE_LINE * V_WHOLE_FRAME) begin
        @(posedge pixel_clk);
      end
    end
  endtask

  task test_random_write;
    begin
      test_line = `__LINE__;
      reset_test();

      vga_enable = 1'b1;
      wr_en      = 1'b1;

      // 3 frames
      repeat (3 * H_WHOLE_LINE * V_WHOLE_FRAME) begin
        @(posedge pixel_clk);
      end
    end
  endtask

  initial begin
    test_idle();
    // test_linear_write();
    // test_even_write();
    // test_random_write();

    $finish;
  end

endmodule
// verilator lint_on UNUSEDSIGNAL
