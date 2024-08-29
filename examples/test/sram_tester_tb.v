`include "testing.v"

`include "sram_tester.v"
`include "sram_model.v"

module sram_tester_tb ();
  // Parameters
  localparam ADDR_BITS = 4;
  localparam DATA_BITS = 2;
  localparam MAX_CYCLES = 50000;

  // Signals
  reg clk;
  reg reset;
  wire test_pass;
  wire test_done;

  // sram controller signals
  wire write_enable;
  wire [ADDR_BITS-1:0] addr;
  wire [DATA_BITS-1:0] write_data;
  wire [DATA_BITS-1:0] read_data;

  // sram controller to io pins
  wire [ADDR_BITS-1:0] addr_bus;
  wire [DATA_BITS-1:0] data_bus;
  wire we_n;
  wire oe_n;
  wire ce_n;

  // sram tester debug signals
  wire [2:0] pattern_state;
  wire [DATA_BITS-1:0] prev_expected_data;
  wire [DATA_BITS-1:0] prev_read_data;

  reg [$clog2(MAX_CYCLES)-1:0] timeout_counter = 0;
  reg [1:0] done_counter = 0;

  sram_tester #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) uut (
      // tester signals
      .clk(clk),
      .reset(reset),
      .test_done(test_done),
      .test_pass(test_pass),

      // sram tester debug signals
      .pattern_state(pattern_state),
      .prev_expected_data(prev_expected_data),
      .prev_read_data(prev_read_data),

      // sram controller signals
      .write_enable(write_enable),
      .addr(addr),
      .write_data(write_data),
      .read_data(read_data),

      // sram controller to io pins
      .addr_bus(addr_bus),
      .data_bus(data_bus),
      .we_n(we_n),
      .oe_n(oe_n),
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

  `TEST_SETUP(sram_tester_tb);

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
    end else begin
      timeout_counter <= timeout_counter + 1;
      `ASSERT(test_pass === 1'b1);
    end
  end

  always @(posedge clk or posedge reset) begin
    if (test_done) begin
      done_counter <= done_counter + 1;
    end
  end

  initial begin
    reset = 1;
    @(posedge clk);
    reset = 0;

    wait (done_counter == 2 || timeout_counter == MAX_CYCLES - 1);
    `ASSERT(done_counter === 2);

    $finish;
  end

endmodule

