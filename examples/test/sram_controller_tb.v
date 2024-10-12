`include "testing.v"

`include "sram_controller.v"
`include "sram_model.v"

module sram_controller_tb;
  localparam ADDR_BITS = 10;
  localparam DATA_BITS = 8;

  reg                  clk;
  reg                  reset;

  reg                  req = 0;
  wire                 ready;

  reg                  write_enable = 0;
  reg  [ADDR_BITS-1:0] addr;
  reg  [DATA_BITS-1:0] write_data;
  wire [DATA_BITS-1:0] read_data;
  wire [ADDR_BITS-1:0] addr_read;

  // chip lines
  wire [ADDR_BITS-1:0] io_addr_bus;
  wire [DATA_BITS-1:0] io_data_bus;
  wire                 io_we_n;
  wire                 io_oe_n;
  wire                 io_ce_n;

  // Instantiate the SRAM controller
  sram_controller #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) ctrl (
      .clk         (clk),
      .reset       (reset),
      .req         (req),
      .ready       (ready),
      .write_enable(write_enable),
      .addr        (addr),
      .write_data  (write_data),
      .read_data   (read_data),
      .io_addr_bus (io_addr_bus),
      .io_we_n     (io_we_n),
      .io_oe_n     (io_oe_n),
      .io_data_bus (io_data_bus),
      .io_ce_n     (io_ce_n)
  );

  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) sram (
      .we_n   (io_we_n),
      .oe_n   (io_oe_n),
      .ce_n   (io_ce_n),
      .addr   (io_addr_bus),
      .data_io(io_data_bus)
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
    `ASSERT(io_oe_n);
    `ASSERT(io_we_n);

    //
    // Single read/write
    //

    // Write
    write_enable = 1;

    req          = 1'b1;
    addr         = 10'h0AA;
    write_data   = 8'hA1;
    @(posedge clk);
    `ASSERT(!ready);
    @(negedge clk);
    `ASSERT(io_addr_bus === 10'h0AA);
    `ASSERT(io_data_bus === 8'hA1);
    `ASSERT(io_oe_n);
    `ASSERT(!io_we_n);

    @(posedge clk);
    `ASSERT(ready);
    `ASSERT(io_oe_n);
    `ASSERT(io_we_n);

    // Read
    write_enable = 0;
    addr         = 10'h0AA;
    @(posedge clk);
    `ASSERT(!ready);
    `ASSERT(~io_oe_n);
    @(posedge clk);
    `ASSERT(io_oe_n);
    `ASSERT(read_data === 8'hA1);
    `ASSERT(ready);

    //
    // Multi write/read
    //

    write_enable = 1;

    // Addr 1
    addr         = 10'h101;
    write_data   = 8'h51;
    @(posedge clk);
    @(posedge clk);

    // Addr 2
    addr       = 10'h102;
    write_data = 8'h52;
    @(posedge clk);
    @(posedge clk);

    // Addr 3
    addr       = 10'h103;
    write_data = 8'h53;
    @(posedge clk);
    @(posedge clk);

    // read cycle
    write_enable = 0;

    addr         = 10'h101;
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
