`include "testing.sv"

`include "adc_xy_vga_fade_stripe.sv"
`include "counter.sv"
`include "sram_model.sv"
`include "sticky_bit.sv"
`include "vga_mode.sv"

// This is not intended to be a full test. This is just to see some wave forms
// in the simulator.
//
// verilator lint_off UNUSEDSIGNAL
module adc_xy_vga_fade_stripe_tb;
  localparam ADC_DATA_BITS = 10;
  localparam PIXEL_BITS = 12;
  localparam COLOR_BITS = PIXEL_BITS / 3;
  localparam AXI_ADDR_WIDTH = 20;
  localparam AXI_DATA_WIDTH = 16;

`ifdef VGA_MODE_640_480_60
  localparam ADC_CLK_HALF_PERIOD = 20;
`else
  // assuming this is 800x600, we have a 40mhz pixel clock.. so with writing
  // full horizontal lines, and with blanking, we need 80mhz of memory bw just
  // for display and blanking. With 2 sram, we have 100mhz. Reduce the adc
  // sample clock to 20mhz.
  localparam ADC_CLK_HALF_PERIOD = 25;
`endif

  logic                      clk;
  logic                      adc_clk;
  logic                      pixel_clk;
  logic                      reset;

  logic [ ADC_DATA_BITS-1:0] adc_x_io;
  logic [ ADC_DATA_BITS-1:0] adc_y_io;
  logic                      adc_red_io;
  logic                      adc_grn_io;
  logic                      adc_blu_io;

  logic [    COLOR_BITS-1:0] vga_red;
  logic [    COLOR_BITS-1:0] vga_grn;
  logic [    COLOR_BITS-1:0] vga_blu;
  logic                      vga_hsync;
  logic                      vga_vsync;

  logic [AXI_ADDR_WIDTH-1:0] sram0_io_addr;
  wire  [AXI_DATA_WIDTH-1:0] sram0_io_data;
  logic                      sram0_io_we_n;
  logic                      sram0_io_oe_n;
  logic                      sram0_io_ce_n;

  logic [AXI_ADDR_WIDTH-1:0] sram1_io_addr;
  wire  [AXI_DATA_WIDTH-1:0] sram1_io_data;
  logic                      sram1_io_we_n;
  logic                      sram1_io_oe_n;
  logic                      sram1_io_ce_n;

  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram_0 (
      .reset  (reset),
      .we_n   (sram0_io_we_n),
      .oe_n   (sram0_io_oe_n),
      .ce_n   (sram0_io_ce_n),
      .addr   (sram0_io_addr),
      .data_io(sram0_io_data)
  );

  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram_1 (
      .reset  (reset),
      .we_n   (sram1_io_we_n),
      .oe_n   (sram1_io_oe_n),
      .ce_n   (sram1_io_ce_n),
      .addr   (sram1_io_addr),
      .data_io(sram1_io_data)
  );

  adc_xy_vga_fade_stripe #(
      .ADC_DATA_BITS (ADC_DATA_BITS),
      .PIXEL_BITS    (PIXEL_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) uut (
      .clk      (clk),
      .adc_clk  (adc_clk),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .adc_x_io  (adc_x_io),
      .adc_y_io  (adc_y_io),
      .adc_red_io(adc_red_io),
      .adc_grn_io(adc_grn_io),
      .adc_blu_io(adc_blu_io),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),

      .sram_io_addr({sram1_io_addr, sram0_io_addr}),
      .sram_io_data({sram1_io_data, sram0_io_data}),
      .sram_io_we_n({sram1_io_we_n, sram0_io_we_n}),
      .sram_io_oe_n({sram1_io_oe_n, sram0_io_oe_n}),
      .sram_io_ce_n({sram1_io_ce_n, sram0_io_ce_n})
  );

  // TODO: add color tests
  assign adc_red_io = 1'b1;
  assign adc_grn_io = 1'b1;
  assign adc_blu_io = 1'b1;

  // TODO: replace with some line pattern that is more representative, but
  // this is a fairly hard pattern as it is basically drawing horizontal
  // lines, which are the hardest for the blanker to keep up with.
  counter #(
      .WIDTH($clog2(1023))
  ) counter_x_inst (
      .clk   (adc_clk),
      .reset (reset),
      .enable(!reset),
      .val   (adc_x_io)
  );

  counter #(
      .WIDTH($clog2(1023))
  ) counter_y_inst (
      .clk   (adc_clk),
      .reset (reset),
      .enable(adc_x_io == '1),
      .val   (adc_y_io)
  );

  // 100mhz
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 25mhz adc clock (no jitter, since we are now the generator)
  initial begin
    adc_clk = 0;
    forever begin
      #ADC_CLK_HALF_PERIOD adc_clk = ~adc_clk;
    end
  end

  // mode specific pixel clock
  initial begin
    pixel_clk = 0;
    forever #`VGA_MODE_TB_PIXEL_CLK pixel_clk = ~pixel_clk;
  end

  `TEST_SETUP_SLOW(adc_xy_vga_fade_stripe_tb)

  always @(posedge adc_clk) begin
    // Ensure we don't drop adc samples
    `ASSERT(!uut.adc_xy_inst.fifo.w_full);
  end

  // checks are enabled once the first pixel makes it through the pipeline
  logic checks_en;
  sticky_bit sticky_checks_en (
      .clk  (pixel_clk),
      .reset(reset),
      .clear(1'b0),
      .in   (!uut.gfx_vga_fade_inst.fifo.r_empty),
      .out  (checks_en)
  );

  always @(posedge pixel_clk) begin
    if (checks_en) begin
      // Ensure we don't drop vga pixels
      `ASSERT(!uut.gfx_vga_fade_inst.fifo_empty);

      // ensure we don't drop blanking pixels
      `ASSERT(!uut.gfx_vga_fade_inst.fade_fifo.w_full);
    end
  end

  // Test stimulus
  initial begin
    reset = 1;
    repeat (20) @(posedge clk);
    reset = 0;

    repeat (4 * `VGA_MODE_H_WHOLE_LINE * `VGA_MODE_V_WHOLE_FRAME + 100) begin
      @(posedge pixel_clk);
    end

    $finish;
  end

endmodule
