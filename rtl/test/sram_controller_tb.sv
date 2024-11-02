`include "testing.sv"

`include "sram_controller.sv"
`include "sram_model.sv"

module sram_controller_tb;
  localparam ADDR_BITS = 10;
  localparam DATA_BITS = 8;

  logic                 clk;
  logic                 reset;

  logic                 req = 0;
  logic                 ready;

  logic                 write_enable = 0;
  logic [ADDR_BITS-1:0] addr;
  logic [DATA_BITS-1:0] write_data;
  // verilator lint_off UNUSEDSIGNAL
  logic                 write_done;
  // verilator lint_on UNUSEDSIGNAL
  logic [DATA_BITS-1:0] read_data;
  logic                 read_data_valid;

  // chip lines
  logic [ADDR_BITS-1:0] io_addr_bus;
  wire  [DATA_BITS-1:0] io_data_bus;
  logic                 io_we_n;
  logic                 io_oe_n;
  logic                 io_ce_n;

  // Instantiate the SRAM controller
  sram_controller #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) ctrl (
      .clk            (clk),
      .reset          (reset),
      .req            (req),
      .ready          (ready),
      .write_enable   (write_enable),
      .addr           (addr),
      .write_data     (write_data),
      .write_done     (write_done),
      .read_data      (read_data),
      .read_data_valid(read_data_valid),
      .io_addr_bus    (io_addr_bus),
      .io_we_n        (io_we_n),
      .io_oe_n        (io_oe_n),
      .io_data_bus    (io_data_bus),
      .io_ce_n        (io_ce_n)
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
    @(negedge clk);
    reset = 0;
    @(posedge clk);
    @(negedge clk);

    `ASSERT(ready);
    `ASSERT(io_oe_n);
    `ASSERT(io_we_n);

    //
    // Multi write/read
    //

    write_enable = 1;
    req          = 1'b1;

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
    @(negedge clk);
    `ASSERT(ready);
    `ASSERT(!read_data_valid);
    write_enable = 0;

    addr         = 10'h101;
    @(posedge clk);
    `ASSERT(!read_data_valid);
    @(posedge clk);
    `ASSERT(!read_data_valid);

    addr = 10'h102;
    @(posedge clk);
    `ASSERT(!read_data_valid);

    // Note: req is set to 0
    req = 0;
    @(posedge clk);
    `ASSERT(!read_data_valid);
    @(negedge clk);
    `ASSERT(read_data_valid);
    `ASSERT(read_data === 8'h51);

    @(posedge clk);
    @(posedge clk);
    `ASSERT(!read_data_valid);
    @(negedge clk);
    `ASSERT(read_data_valid);
    `ASSERT(read_data === 8'h52);

    @(posedge clk);
    @(negedge clk);
    `ASSERT(!read_data_valid);

    `ASSERT(ready);
    req  = 1;
    addr = 10'h103;
    @(posedge clk);
    `ASSERT(!read_data_valid);
    @(posedge clk);
    `ASSERT(!read_data_valid);
    @(posedge clk);
    `ASSERT(!read_data_valid);
    @(posedge clk);
    @(negedge clk);
    `ASSERT(read_data_valid);
    `ASSERT(read_data === 8'h53);

    $finish;
  end

endmodule
