`include "testing.sv"
`include "cdc_fifo.sv"

module cdc_fifo_tb;

  parameter DATA_WIDTH = 8;
  parameter ADDR_SIZE = 4;

  logic                  w_clk;
  logic                  w_rst_n;
  logic                  w_inc;
  logic [DATA_WIDTH-1:0] w_data;

  // verilator lint_off UNUSEDSIGNAL
  logic                  w_almost_full;
  // verilator lint_on UNUSEDSIGNAL

  logic                  w_full;

  logic                  r_clk;
  logic                  r_rst_n;
  logic                  r_inc;
  logic                  r_empty;
  logic [DATA_WIDTH-1:0] r_data;

  cdc_fifo #(
      .DATA_WIDTH     (DATA_WIDTH),
      .ADDR_SIZE      (ADDR_SIZE),
      .ALMOST_FULL_BUF(4)
  ) dut (
      .w_clk        (w_clk),
      .w_rst_n      (w_rst_n),
      .w_inc        (w_inc),
      .w_data       (w_data),
      .w_almost_full(w_almost_full),
      .w_full       (w_full),
      .r_clk        (r_clk),
      .r_rst_n      (r_rst_n),
      .r_inc        (r_inc),
      .r_empty      (r_empty),
      .r_data       (r_data)
  );

  `TEST_SETUP(cdc_fifo_tb)

  // Write clock generation
  initial begin
    w_clk = 0;
    forever #5 w_clk = ~w_clk;
  end

  // Read clock generation
  initial begin
    r_clk = 0;
    forever #7 r_clk = ~r_clk;
  end

  logic [7:0] val;

  // Test scenario
  initial begin
    // Initialize inputs
    w_rst_n = 0;
    r_rst_n = 0;
    w_inc   = 0;
    r_inc   = 0;
    w_data  = 0;

    #20;
    w_rst_n = 1;
    r_rst_n = 1;
    #20;

    `ASSERT(r_empty === 1'b1)
    `ASSERT(w_full === 1'b0)

    // Write data
    w_inc = 1;
    val   = 42;
    repeat (15) begin
      w_data = val;
      val    = val + 1;
      @(posedge w_clk);
      @(negedge w_clk);
      `ASSERT(w_full === 1'b0)
    end

    // Check full condition
    @(posedge w_clk);
    @(negedge w_clk);
    `ASSERT(w_full === 1'b1);

    // Stop writes so we can test read empty
    w_inc = 0;
    @(posedge w_clk);

    // Read data
    `ASSERT(r_empty === 1'b0)
    r_inc = 1;
    val   = 42;
    repeat (15) begin
      `ASSERT(r_data === val);
      @(posedge r_clk);
      @(negedge r_clk);
      `ASSERT(r_empty === 1'b0)
      val = val + 1;
    end

    // Check empty condition
    @(posedge r_clk);
    @(negedge r_clk);
    `ASSERT(r_empty === 1'b1)

    // TODO: more complicated randomized/stress testing

    // Add more data after wrap around
    r_inc = 0;
    w_inc = 1;
    val   = 100;
    repeat (15) begin
      w_data = val;
      val    = val + 1;
      @(posedge w_clk);
      @(negedge w_clk);
      `ASSERT(w_full === 1'b0)
    end

    $finish;
  end

endmodule
