`include "testing.sv"

`include "sram_tester_axi.sv"
`include "sram_model.sv"

// verilator lint_off UNUSEDSIGNAL
module sram_tester_axi_tb ();
  localparam ADDR_BITS = 4;
  localparam DATA_BITS = 2;
  localparam MAX_CYCLES = 50000;

  // Signals
  reg                           clk;
  reg                           reset;
  wire                          test_pass;
  wire                          test_done;

  // sram tester debug signals
  wire [                   2:0] pattern_state;
  wire [         DATA_BITS-1:0] prev_expected_data;
  wire [         DATA_BITS-1:0] prev_read_data;
  wire [         ADDR_BITS-1:0] iter_addr;

  //
  // SRAM Interface
  wire [         ADDR_BITS-1:0] sram_io_addr;
  wire [         DATA_BITS-1:0] sram_io_data;
  wire                          sram_io_we_n;
  wire                          sram_io_oe_n;
  wire                          sram_io_ce_n;

  // Unit test signals
  reg  [$clog2(MAX_CYCLES)-1:0] timeout_counter = 0;
  reg  [                   1:0] done_counter = 0;

  // Instantiate the AXI SRAM controller
  sram_tester_axi #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) tester (
      // tester signals
      .clk      (clk),
      .reset    (reset),
      .test_done(test_done),
      .test_pass(test_pass),

      // sram tester debug signals
      .pattern_state     (pattern_state),
      .prev_expected_data(prev_expected_data),
      .prev_read_data    (prev_read_data),
      .iter_addr         (iter_addr),

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
      .we_n   (sram_io_we_n),
      .oe_n   (sram_io_oe_n),
      .ce_n   (sram_io_ce_n),
      .addr   (sram_io_addr),
      .data_io(sram_io_data)
  );

  `TEST_SETUP(sram_tester_axi_tb);

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
    @(negedge clk);
    reset = 0;

    wait (done_counter == 2 || timeout_counter == MAX_CYCLES - 1);
    `ASSERT(done_counter === 2);

    $finish;
  end

endmodule
// verilator lint_on UNUSEDSIGNAL

