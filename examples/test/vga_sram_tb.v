`include "testing.v"
`include "sram_model.v"

`include "vga_sram.v"

// This is not intended to be a full test. This is just to see some wave forms
// in the simulator.

// verilator lint_off UNUSEDSIGNAL

module vga_sram_tb;

  parameter AXI_ADDR_WIDTH = 20;
  parameter AXI_DATA_WIDTH = 16;

  reg                       clk;
  reg                       pixel_clk;
  reg                       reset;

  // SRAM Interface
  wire [AXI_ADDR_WIDTH-1:0] sram_io_addr;
  wire [AXI_DATA_WIDTH-1:0] sram_io_data;
  wire                      sram_io_we_n;
  wire                      sram_io_oe_n;
  wire                      sram_io_ce_n;

  // Vga signals
  wire                      vga_vsync;
  wire                      vga_hsync;

  wire [               3:0] vga_red;
  wire [               3:0] vga_green;
  wire [               3:0] vga_blue;

  vga_sram #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) uut (
      .clk      (clk),
      .pixel_clk(pixel_clk),
      .reset    (reset),

      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n),

      .vga_red  (vga_red),
      .vga_green(vga_green),
      .vga_blue (vga_blue),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync)

  );

  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram (
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

  // 25mhz pixel clock
  initial begin
    pixel_clk = 0;
    forever #20 pixel_clk = ~pixel_clk;
  end

  `TEST_SETUP_SLOW(vga_sram_tb);

  // Test procedure
  initial begin
    reset = 1;
    repeat (10) @(posedge clk);
    reset = 0;

    // This is for the pattern generantor
    repeat (640 * 480) @(posedge clk);

    // This is for the display.
    // The 800 * 525 are the H_WHOLE_LINE * V_WHOLE_FRAME.
    // TODO: make these configurable
    repeat (3 * 800 * 525) @(posedge pixel_clk);
    $finish;
  end

endmodule

// verilator lint_on UNUSEDSIGNAL
