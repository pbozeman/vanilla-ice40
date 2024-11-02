`include "testing.sv"

`include "sram_tester.sv"
`include "sram_model.sv"

// This test logics everything up and then runs the test
// and makes sure it completes. It doesn't check signals
// itself.
//
// verilator lint_off UNUSEDSIGNAL
module sram_tester_tb ();
  // Parameters
  localparam ADDR_BITS = 4;
  localparam DATA_BITS = 2;
  localparam MAX_CYCLES = 50000;

  // Signals
  logic                          clk;
  logic                          reset;
  logic                          test_pass;
  logic                          test_done;

  // sram controller signals
  logic                          sram_write_enable;
  logic [         ADDR_BITS-1:0] sram_addr;
  logic [         DATA_BITS-1:0] sram_write_data;
  logic [         DATA_BITS-1:0] sram_read_data;

  // sram controller to io pins
  logic [         ADDR_BITS-1:0] sram_io_addr_bus;
  wire  [         DATA_BITS-1:0] sram_io_data_bus;
  logic                          sram_io_we_n;
  logic                          sram_io_oe_n;
  logic                          sram_io_ce_n;

  // sram tester debug signals
  logic [                   2:0] pattern_state;
  logic [         DATA_BITS-1:0] prev_expected_data;
  logic [         DATA_BITS-1:0] prev_read_data;

  logic [$clog2(MAX_CYCLES)-1:0] timeout_counter = 0;
  logic [                   1:0] done_counter = 0;

  sram_tester #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) uut (
      // tester signals
      .clk      (clk),
      .reset    (reset),
      .test_done(test_done),
      .test_pass(test_pass),

      // sram tester debug signals
      .pattern_state     (pattern_state),
      .prev_expected_data(prev_expected_data),
      .prev_read_data    (prev_read_data),

      // sram controller signals
      .sram_write_enable(sram_write_enable),
      .sram_addr        (sram_addr),
      .sram_write_data  (sram_write_data),
      .sram_read_data   (sram_read_data),

      // sram controller to io pins
      .sram_io_addr_bus(sram_io_addr_bus),
      .sram_io_data_bus(sram_io_data_bus),
      .sram_io_we_n    (sram_io_we_n),
      .sram_io_oe_n    (sram_io_oe_n),
      .sram_io_ce_n    (sram_io_ce_n)
  );

  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) sram (
      .we_n   (sram_io_we_n),
      .oe_n   (sram_io_oe_n),
      .ce_n   (sram_io_ce_n),
      .addr   (sram_io_addr_bus),
      .data_io(sram_io_data_bus)
  );

  `TEST_SETUP(sram_tester_tb);

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

    wait (done_counter == 2 || timeout_counter == MAX_CYCLES - 1);
    `ASSERT(done_counter === 2);

    $finish;
  end

endmodule

// verilator lint_on UNUSEDSIGNAL
