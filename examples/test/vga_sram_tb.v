`include "testing.v"

`include "vga_sram.v"

module vga_sram_tb;

  parameter ADDR_BITS = 20;
  parameter DATA_BITS = 16;

  // Inputs
  reg clk;
  reg reset;

  // Outputs
  wire [3:0] vga_red;
  wire [3:0] vga_green;
  wire [3:0] vga_blue;
  wire vga_hsync;
  wire vga_vsync;
  wire [ADDR_BITS-1:0] addr_bus;
  wire we_n;
  wire oe_n;
  wire ce_n;

  // Bidirectional
  wire [DATA_BITS-1:0] data_bus_io;

  // Instantiate the Unit Under Test (UUT)
  vga_sram #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) uut (
      .clk(clk),
      .reset(reset),
      .vga_red(vga_red),
      .vga_green(vga_green),
      .vga_blue(vga_blue),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .addr_bus(addr_bus),
      .data_bus_io(data_bus_io),
      .we_n(we_n),
      .oe_n(oe_n),
      .ce_n(ce_n)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
  end

  // Dummy SRAM model
  reg [DATA_BITS-1:0] sram_mem[0:(1<<ADDR_BITS)-1];
  assign data_bus_io = !oe_n ? sram_mem[addr_bus] : {DATA_BITS{1'bz}};

  always @(posedge clk) begin
    if (!we_n && !ce_n) begin
      sram_mem[addr_bus] <= data_bus_io;
    end
  end

  `TEST_SETUP(vga_sram_tb)

  // Test procedure
  initial begin
    // Initialize Inputs
    reset = 1;
    #100;
    reset = 0;

    // Wait for pattern generation to complete
    wait (uut.pattern_done);
    `ASSERT(uut.pattern_done == 1);

    // Check if SRAM was written to
    `ASSERT(sram_mem[0] !== 16'bx);

    // Wait for a few frames to be displayed
    repeat (3) @(posedge vga_vsync);

    // Check if VGA signals are being generated
    `ASSERT(vga_red !== 4'bx);
    `ASSERT(vga_green !== 4'bx);
    `ASSERT(vga_blue !== 4'bx);

    // Add more specific checks here based on your expected pattern

    $display("Test completed successfully");
    $finish;
  end

endmodule
