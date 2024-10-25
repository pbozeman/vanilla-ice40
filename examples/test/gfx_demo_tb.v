`include "testing.v"

`include "gfx_demo.v"

// This is not intended to be a full test. This is just to see some wave forms
// in the simulator.
//
// verilator lint_off UNUSEDSIGNAL
module gfx_demo_tb;
  localparam VGA_WIDTH = 640;
  localparam VGA_HEIGHT = 480;

  localparam FB_X_BITS = $clog2(VGA_WIDTH);
  localparam FB_Y_BITS = $clog2(VGA_HEIGHT);

  reg                  clk;
  reg                  pixel_clk;
  reg                  reset;

  wire [FB_X_BITS-1:0] x;
  wire [FB_Y_BITS-1:0] y;

  gfx_demo uut (
      .clk  (clk),
      .reset(reset),
      .x    (x),
      .y    (y)
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

    // This is for the pattern generator
    repeat (640 * 480 + 100) @(posedge clk);

    // This is for the display.
    // The 800 * 525 are the H_WHOLE_LINE * V_WHOLE_FRAME.
    // // TODO: make these configurable
    // repeat (3 * 800 * 525) @(posedge pixel_clk);
    $finish;
  end

endmodule
// verilator lint_on UNUSEDSIGNAL
