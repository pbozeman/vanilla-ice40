`include "testing.sv"

`include "adc_xy_vga.sv"
`include "counter.sv"
`include "sram_model.sv"
`include "vga_mode.sv"

// This is not intended to be a full test. This is just to see some wave forms
// in the simulator.
//
// verilator lint_off UNUSEDSIGNAL
module adc_xy_vga_tb;
  localparam ADC_DATA_BITS = 10;
  localparam PIXEL_BITS = 12;
  localparam META_BITS = 4;
  localparam COLOR_BITS = PIXEL_BITS / 3;
  localparam AXI_ADDR_WIDTH = 20;
  localparam AXI_DATA_WIDTH = 16;

  logic                      clk;
  logic                      adc_clk;
  logic                      pixel_clk;
  logic                      reset;

  logic [ ADC_DATA_BITS-1:0] adc_x_io;
  logic [ ADC_DATA_BITS-1:0] adc_y_io;

  logic [    COLOR_BITS-1:0] vga_red;
  logic [    COLOR_BITS-1:0] vga_grn;
  logic [    COLOR_BITS-1:0] vga_blu;
  logic [     META_BITS-1:0] vga_meta;
  logic                      vga_hsync;
  logic                      vga_vsync;

  logic [AXI_ADDR_WIDTH-1:0] sram0_io_addr;
  wire  [AXI_DATA_WIDTH-1:0] sram0_io_data;
  logic                      sram0_io_we_n;
  logic                      sram0_io_oe_n;
  logic                      sram0_io_ce_n;

  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram_0 (
      .we_n   (sram0_io_we_n),
      .oe_n   (sram0_io_oe_n),
      .ce_n   (sram0_io_ce_n),
      .addr   (sram0_io_addr),
      .data_io(sram0_io_data)
  );

  adc_xy_vga #(
      .ADC_DATA_BITS (ADC_DATA_BITS),
      .PIXEL_BITS    (PIXEL_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) uut (
      .clk      (clk),
      .adc_clk  (adc_clk),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .adc_x_io(adc_x_io),
      .adc_y_io(adc_y_io),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_meta (vga_meta),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),

      .sram0_io_addr(sram0_io_addr),
      .sram0_io_data(sram0_io_data),
      .sram0_io_we_n(sram0_io_we_n),
      .sram0_io_oe_n(sram0_io_oe_n),
      .sram0_io_ce_n(sram0_io_ce_n)
  );

  counter #(
      .MAX_VALUE(1024)
  ) counter_x_inst (
      .clk   (adc_clk),
      .reset (reset),
      .enable(!reset),
      .count (adc_x_io)
  );

  counter #(
      .MAX_VALUE(1024)
  ) counter_y_inst (
      .clk   (adc_clk),
      .reset (reset),
      .enable(!reset),
      .count (adc_y_io)
  );

  // 100mhz
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 50mhz
  initial begin
    adc_clk = 0;
    forever #10 adc_clk = ~adc_clk;
  end

  // mode specific pixel clock
  initial begin
    pixel_clk = 0;
    forever #`VGA_MODE_TB_PIXEL_CLK pixel_clk = ~pixel_clk;
  end

  `TEST_SETUP_SLOW(adc_xy_vga_tb)

  // Test stimulus
  initial begin
    reset = 1;
    repeat (10) @(posedge clk);
    reset = 0;

    repeat (4 * `VGA_MODE_H_WHOLE_LINE * `VGA_MODE_V_WHOLE_FRAME + 100) begin
      @(posedge pixel_clk);
    end

    $finish;
  end

endmodule
