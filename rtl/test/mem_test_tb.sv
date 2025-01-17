`include "testing.sv"

`include "mem_test.sv"
`include "sram_model.sv"

// verilator lint_off UNUSEDSIGNAL
module mem_test_tb ();
  localparam ADDR_BITS = 8;
  localparam DATA_BITS = 8;
  localparam MAX_CYCLES = 50000;

  // Signals
  logic                          clk;
  logic                          reset;
  logic                          test_pass;
  logic                          test_done;

  //
  // SRAM Interface
  logic [         ADDR_BITS-1:0] sram_io_addr;
  wire  [         DATA_BITS-1:0] sram_io_data;
  logic                          sram_io_we_n;
  logic                          sram_io_oe_n;
  logic                          sram_io_ce_n;

  // Unit test signals
  logic [$clog2(MAX_CYCLES)-1:0] timeout_counter = 0;
  logic [                   1:0] done_counter = 0;

  // Instantiate the AXI SRAM controller
  mem_test #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) tester (
      // tester signals
      .clk      (clk),
      .reset    (reset),
      .test_done(test_done),
      .test_pass(test_pass),

      .debug0(),
      .debug1(),

      // sram controller to io pins
      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) sram (
      .reset  (reset),
      .we_n   (sram_io_we_n),
      .oe_n   (sram_io_oe_n),
      .ce_n   (sram_io_ce_n),
      .addr   (sram_io_addr),
      .data_io(sram_io_data)
  );

  `TEST_SETUP(mem_test_tb);

  // Clock generation
  initial begin
    // 10ns period clock
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Timeout counter logic
  always @(posedge clk) begin
    if (reset) begin
      timeout_counter <= 0;
    end else begin
      timeout_counter <= timeout_counter + 1;
      `ASSERT(test_pass === 1'b1);
    end
  end

  always @(posedge clk) begin
    if (test_done) begin
      done_counter <= done_counter + 1;
    end
  end

  initial begin
    reset = 1;
    @(posedge clk);
    @(posedge clk);
    reset = 0;
    @(posedge clk);

    wait (done_counter == 2 || timeout_counter == MAX_CYCLES - 1);
    `ASSERT_EQ(done_counter, 2);

    $finish;
  end

endmodule
// verilator lint_on UNUSEDSIGNAL

