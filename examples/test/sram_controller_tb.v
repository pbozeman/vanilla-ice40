`include "testing.v"

`include "sram_controller.v"
`include "sram_model.v"

module sram_controller_tb;
  localparam ADDR_BITS = 10;
  localparam DATA_BITS = 8;

  reg clk;
  reg reset;

  reg req = 0;
  wire ready;

  reg write_enable = 0;
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

  // Instantiate the SRAM controller
  sram_controller #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) ctrl (
      .clk(clk),
      .reset(reset),
      .req(req),
      .ready(ready),
      .write_enable(write_enable),
      .addr(addr),
      .write_data(write_data),
      .read_data(read_data),
      .addr_bus(addr_bus),
      .we_n(we_n),
      .oe_n(oe_n),
      .data_bus_io(data_bus),
      .ce_n(ce_n)
  );

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

  // Clock generation
  initial begin
    clk = 0;

    // 10ns period clock
    forever #5 clk = ~clk;
  end

  `TEST_SETUP(sram_controller_tb);

  // Test sequence
  initial begin
    // Reset
    reset = 1;
    @(posedge clk);
    reset = 0;

    `ASSERT(ready);
    `ASSERT(oe_n);
    `ASSERT(we_n);

    //
    // Single read/write
    //

    // Write
    write_enable = 1;

    req = 1'b1;
    addr = 10'h0AA;
    write_data = 8'hA1;
    @(posedge clk);
    `ASSERT(!ready);
    `ASSERT(addr_bus === 10'h0AA);
    `ASSERT(data_bus === 8'hA1);
    `ASSERT(oe_n);
    `ASSERT(!we_n);

    @(posedge clk);
    `ASSERT(ready);
    `ASSERT(oe_n);
    `ASSERT(we_n);

    // Read
    write_enable = 0;
    addr = 10'h0AA;
    @(posedge clk);
    `ASSERT(!ready);
    `ASSERT(~oe_n);
    @(posedge clk);
    `ASSERT(oe_n);
    `ASSERT(read_data === 8'hA1);
    `ASSERT(ready);

    //
    // Multi write/read
    //

    write_enable = 1;

    // Addr 1
    addr = 10'h101;
    write_data = 8'h51;
    @(posedge clk);
    @(posedge clk);

    // Addr 2
    addr = 10'h102;
    write_data = 8'h52;
    @(posedge clk);
    @(posedge clk);

    // Addr 3
    addr = 10'h103;
    write_data = 8'h53;
    @(posedge clk);
    @(posedge clk);

    // read cycle
    write_enable = 0;

    addr = 10'h101;
    @(posedge clk);
    @(posedge clk);
    `ASSERT(read_data === 8'h51);

    addr = 10'h102;
    @(posedge clk);
    @(posedge clk);
    `ASSERT(read_data === 8'h52);

    // Note: req is set to 0
    req  = 0;
    addr = 10'h103;
    @(posedge clk);
    `ASSERT(read_data === 8'h52);

    // go back to reading
    req = 1;
    @(posedge clk);
    @(posedge clk);
    `ASSERT(read_data === 8'h53);

    $finish;
  end

endmodule
