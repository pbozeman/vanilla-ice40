`include "testing.v"

`include "sram_controller.v"
`include "sram_model.v"

module sram_controller_tb;
  localparam ADDR_BITS = 10;
  localparam DATA_BITS = 8;

  reg clk;
  reg reset;
  reg read_only;
  reg [ADDR_BITS-1:0] addr;
  reg [DATA_BITS-1:0] write_data;
  wire [DATA_BITS-1:0] read_data;
  wire [ADDR_BITS-1:0] addr_read;

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
      .we_n(we_n),
      .oe_n(oe_n),
      .ce_n(ce_n),
      .addr(addr_bus),
      .data_io(data_bus)
  );

  // Instantiate the SRAM controller
  sram_controller #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) ctrl (
      .clk(clk),
      .reset(reset),
      .read_only(read_only),
      .addr(addr),
      .data_i(write_data),
      .data_o(read_data),
      .data_o_addr(addr_read),
      .addr_bus(addr_bus),
      .we_n(we_n),
      .oe_n(oe_n),
      .data_bus_io(data_bus),
      .ce_n(ce_n)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10ns period clock
  end

  `TEST_SETUP(sram_controller_tb);

  // Test sequence
  initial begin
    // Initialize control signals
    reset = 1;
    read_only = 0;
    addr = 10'h0;
    write_data = 8'h00;

    // Reset sequence
    #10 reset = 0;
    @(posedge clk);

    // Write cycle
    read_only = 0;
    addr = 10'h100;
    write_data = 8'hA1;
    @(posedge clk);

    // Addr 2
    addr = 10'h101;
    write_data = 8'hB2;
    @(posedge clk);

    // Addr 3
    addr = 10'h102;
    write_data = 8'hC3;
    @(posedge clk);

    // switch directions
    read_only = 1;

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
    `ASSERT(read_data === 8'hA1);

    addr = 10'h102;
    @(posedge clk);
    `ASSERT(read_data === 8'hB2);

    @(posedge clk);
    `ASSERT(read_data === 8'hC3);

    $finish;
  end

endmodule
