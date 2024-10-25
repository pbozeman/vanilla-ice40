`include "testing.v"

`include "gfx_demo.v"
`include "sram_model.v"

// This is not intended to be a full test. This is just to see some wave forms
// in the simulator.
//
// verilator lint_off UNUSEDSIGNAL
module gfx_demo_tb;
  // localparam VGA_WIDTH = 640;
  // localparam VGA_HEIGHT = 480;
  localparam PIXEL_BITS = 12;

  parameter AXI_ADDR_WIDTH = 20;
  parameter AXI_DATA_WIDTH = 16;

  reg                       clk;
  reg                       pixel_clk;
  reg                       reset;

  wire [AXI_ADDR_WIDTH-1:0] addr;
  wire [    PIXEL_BITS-1:0] color;

  // SRAM 0
  wire [AXI_ADDR_WIDTH-1:0] sram0_io_addr;
  wire [AXI_DATA_WIDTH-1:0] sram0_io_data;
  wire                      sram0_io_we_n;
  wire                      sram0_io_oe_n;
  wire                      sram0_io_ce_n;

  // SRAM 1
  wire [AXI_ADDR_WIDTH-1:0] sram1_io_addr;
  wire [AXI_DATA_WIDTH-1:0] sram1_io_data;
  wire                      sram1_io_we_n;
  wire                      sram1_io_oe_n;
  wire                      sram1_io_ce_n;

  gfx_demo uut (
      .clk  (clk),
      .reset(reset),
      .addr (addr),
      .color(color),

      .sram0_io_addr(sram0_io_addr),
      .sram0_io_data(sram0_io_data),
      .sram0_io_we_n(sram0_io_we_n),
      .sram0_io_oe_n(sram0_io_oe_n),
      .sram0_io_ce_n(sram0_io_ce_n),

      .sram1_io_addr(sram1_io_addr),
      .sram1_io_data(sram1_io_data),
      .sram1_io_we_n(sram1_io_we_n),
      .sram1_io_oe_n(sram1_io_oe_n),
      .sram1_io_ce_n(sram1_io_ce_n)
  );

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

  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram_1 (
      .we_n   (sram1_io_we_n),
      .oe_n   (sram1_io_oe_n),
      .ce_n   (sram1_io_ce_n),
      .addr   (sram1_io_addr),
      .data_io(sram1_io_data)
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

  `TEST_SETUP_SLOW(gfx_demo_tb);

  // Test procedure
  initial begin
    reset = 1;
    repeat (10) @(posedge clk);
    reset = 0;

    // This is for the pattern generator (2x because of the sram, +100 to see
    // into the next frame)
    repeat (2 * 640 * 480 + 100) @(posedge clk);

    // This is for the display.
    // The 800 * 525 are the H_WHOLE_LINE * V_WHOLE_FRAME.
    // // TODO: make these configurable
    // repeat (3 * 800 * 525) @(posedge pixel_clk);
    $finish;
  end

endmodule
// verilator lint_on UNUSEDSIGNAL
