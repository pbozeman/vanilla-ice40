`include "testing.sv"

`include "gfx_demo.sv"
`include "sram_model.sv"
`include "vga_mode.sv"

// This is not intended to be a full test. This is just to see some wave forms
// in the simulator.
//
// verilator lint_off UNUSEDSIGNAL
module gfx_demo_tb;
  localparam PIXEL_BITS = 12;

  localparam AXI_ADDR_WIDTH = 20;
  localparam AXI_DATA_WIDTH = 16;

  localparam COLOR_BITS = PIXEL_BITS / 3;

  reg                       clk;
  reg                       pixel_clk;
  reg                       reset;

  wire [AXI_ADDR_WIDTH-1:0] addr;
  wire [    PIXEL_BITS-1:0] color;

  // SRAM 0
  wire [AXI_ADDR_WIDTH-1:0] sram_io_addr;
  wire [AXI_DATA_WIDTH-1:0] sram_io_data;
  wire                      sram_io_we_n;
  wire                      sram_io_oe_n;
  wire                      sram_io_ce_n;

  wire [    COLOR_BITS-1:0] vga_red;
  wire [    COLOR_BITS-1:0] vga_grn;
  wire [    COLOR_BITS-1:0] vga_blu;
  wire                      vga_hsync;
  wire                      vga_vsync;

  gfx_demo uut (
      .clk      (clk),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),

      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram_0 (
      .we_n   (sram_io_we_n),
      .oe_n   (sram_io_oe_n),
      .ce_n   (sram_io_ce_n),
      .addr   (sram_io_addr),
      .data_io(sram_io_data)
  );

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

  `TEST_SETUP_SLOW(gfx_demo_tb);

  // Test procedure
  initial begin
    reset = 1;
    repeat (10) @(posedge clk);
    reset = 0;

    repeat (2 * `VGA_MODE_H_VISIBLE * `VGA_MODE_V_VISIBLE + 100) begin
      @(posedge clk);
    end

    // This is for the display.
    repeat (3 * `VGA_MODE_H_WHOLE_LINE * `VGA_MODE_V_WHOLE_FRAME) begin
      @(posedge pixel_clk);
    end

    $finish;
  end

endmodule
// verilator lint_on UNUSEDSIGNAL
