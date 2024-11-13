`include "testing.sv"
`include "sync_fifo.sv"

module sync_fifo_tb;
  // Parameters
  localparam DATA_WIDTH = 8;
  localparam ADDR_SIZE = 4;
  localparam DEPTH = 1 << ADDR_SIZE;

  // Signals
  logic                  clk;
  logic                  rst_n;
  logic                  w_inc;
  logic [DATA_WIDTH-1:0] w_data;
  logic                  w_full;
  logic                  r_inc;
  logic                  r_empty;
  logic [DATA_WIDTH-1:0] r_data;

  // DUT instantiation
  sync_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_SIZE (ADDR_SIZE)
  ) dut (
      .clk    (clk),
      .rst_n  (rst_n),
      .w_inc  (w_inc),
      .w_data (w_data),
      .w_full (w_full),
      .r_inc  (r_inc),
      .r_empty(r_empty),
      .r_data (r_data)
  );

  `TEST_SETUP(sync_fifo_tb)

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n  = 1;
    w_inc  = 0;
    w_data = 0;
    r_inc  = 0;

    // Reset sequence
    @(posedge clk);
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Test 1: Verify empty condition after reset
    `ASSERT(r_empty === 1'b1)
    `ASSERT(w_full === 1'b0)

    // Test 2: Write single value
    w_data = 8'hA5;
    w_inc  = 1;
    @(posedge clk);
    w_inc = 0;
    `ASSERT(r_empty === 1'b0)
    `ASSERT_EQ(r_data, 8'hA5)
    @(posedge clk);

    // Test 3: Read single value and verify empty on same clock
    r_inc = 1;
    @(posedge clk);
    r_inc = 0;
    #1;
    `ASSERT(r_empty === 1'b1)

    // Test 4: Fill FIFO
    for (int i = 0; i < DEPTH; i++) begin
      w_data = i[DATA_WIDTH-1:0];
      w_inc  = 1;
      @(posedge clk);
      @(negedge clk);
      `ASSERT(w_full === (i === DEPTH - 1))
    end
    w_inc = 0;

    // Test 5: Read all values and verify
    for (int i = 0; i < DEPTH; i++) begin
      `ASSERT_EQ(r_data, i[DATA_WIDTH-1:0])
      r_inc = 1;
      @(posedge clk);
      @(negedge clk);
    end
    r_inc = 0;

    // Test 6: Verify empty after reading all
    `ASSERT(r_empty === 1'b1)

    $finish;
  end
endmodule
