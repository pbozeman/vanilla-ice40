// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module sram_controller_tb;
  localparam ADDR_BITS = 10;
  localparam DATA_BITS = 8;

  reg clk;
  reg reset;
  reg rw;
  reg [ADDR_BITS-1:0] addr;
  reg [DATA_BITS-1:0] data_write;
  wire [DATA_BITS-1:0] data_read;

  // chip lines
  wire [ADDR_BITS-1:0] addr_bus;
  wire [DATA_BITS-1:0] data_bus;
  wire we_n;
  wire oe_n;
  wire ce_n;

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

  // Instantiate the SRAM controller
  sram_controller #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) ctrl (
      .clk_i(clk),
      .reset_i(reset),
      .rw_i(rw),
      .addr_i(addr),
      .data_i(data_write),
      .data_o(data_read),
      .addr_bus_o(addr_bus),
      .we_n_o(we_n),
      .oe_n_o(oe_n),
      .data_bus_io(data_bus),
      .ce_n_o(ce_n)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10ns period clock
  end

  // Test sequence
  initial begin
    $dumpfile(".build/sram_controller_tb.vcd");
    $dumpvars(0, sram_controller_tb);

    // Initialize control signals
    reset = 1;
    rw = 0;
    addr = 10'h0;
    data_write = 8'h00;

    // Reset sequence
    #10 reset = 0;
    @(posedge clk);

    // Write cycle
    rw = 0;
    addr = 10'h100;
    data_write = 8'hA1;
    @(posedge clk);

    // Addr 2
    addr = 10'h101;
    data_write = 8'hB2;
    @(posedge clk);

    // Addr 3
    addr = 10'h102;
    data_write = 8'hC3;
    @(posedge clk);

    // switch directions
    rw = 1;

    // need 1 clock to switch direction, otherwise, we write as we change addr
    // (this may not be true for a real chip)
    @(posedge clk);

    // set the addr, and clock a read
    addr = 10'h100;
    @(posedge clk);

    // now that we changed directions, and set an addr, we can read every
    // clock... we are reading the value from the previous addr, and setting
    // the new addr in a pipeline
    addr = 10'h101;
    @(posedge clk);
    `ASSERT(data_read === 8'hA1);

    addr = 10'h102;
    @(posedge clk);
    `ASSERT(data_read === 8'hB2);

    @(posedge clk);
    `ASSERT(data_read === 8'hC3);

    $finish;
  end

endmodule
