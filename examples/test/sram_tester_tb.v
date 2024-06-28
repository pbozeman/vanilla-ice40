`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module sram_tester_tb ();

  // Parameters
  localparam ADDR_BITS = 10;
  localparam DATA_BITS = 8;
  localparam MAX_CYCLES = 100000;

  // Signals
  reg clk;
  reg reset;
  wire test_done;
  wire test_pass;

  // sram pins
  wire rw;
  wire [ADDR_BITS-1:0] addr;
  wire [DATA_BITS-1:0] data_write;
  wire [DATA_BITS-1:0] data_read;
  wire [ADDR_BITS-1:0] addr_bus;
  wire [DATA_BITS-1:0] data_bus;
  wire we_n;
  wire oe_n;
  wire ce_n;

  reg [$clog2(MAX_CYCLES)-1:0] timeout_counter = 0;

  sram_tester #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) uut (
      .clk(clk),
      .reset(reset),
      .test_done(test_done),
      .test_pass(test_pass),
      .rw(rw),
      .addr(addr),
      .data_write(data_write),
      .data_read(data_read),
      .addr_bus(addr_bus),
      .we_n(we_n),
      .oe_n(oe_n),
      .data_bus(data_bus),
      .ce_n(ce_n)

  );

  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) sram (
      .we_n_i (we_n),
      .oe_n_i (oe_n),
      .ce_n_i (ce_n),
      .addr_i (addr_bus),
      .data_io(data_bus)
  );

  // Clock generation
  initial begin
    // 10ns period clock
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Timeout counter logic
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      timeout_counter <= 0;
    end else if (!test_done) begin
      timeout_counter <= timeout_counter + 1;
    end
  end

  // Testbench stimulus
  initial begin
    $dumpfile(".build/sram_tester.vcd");
    $dumpvars(0, sram_tester_tb);

    // Initialize Inputs
    reset = 1;

    // Wait 10 ns for global reset to finish
    #10;

    // Release reset
    reset = 0;

    // Wait for test to complete or timeout
    wait (test_done || (timeout_counter == MAX_CYCLES - 1));

    `ASSERT(test_done);

    // Add some delay after test completion
    #10;

    // Finish the simulation
    $finish;
  end

endmodule
