`include "testing.v"
`include "cdc_fifo.v"

module cdc_fifo_tb;

  parameter DATA_WIDTH = 8;
  parameter ADDR_SIZE = 4;

  reg w_clk;
  reg w_rst_n;
  reg w_inc;
  reg [DATA_WIDTH-1:0] w_data;
  wire w_almost_full;
  wire w_full;

  reg r_clk;
  reg r_rst_n;
  reg r_inc;
  wire r_empty;
  wire [DATA_WIDTH-1:0] r_data;

  cdc_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_SIZE (ADDR_SIZE)
  ) dut (
      .w_clk(w_clk),
      .w_rst_n(w_rst_n),
      .w_inc(w_inc),
      .w_data(w_data),
      .w_almost_full(w_almost_full),
      .w_full(w_full),
      .r_clk(r_clk),
      .r_rst_n(r_rst_n),
      .r_inc(r_inc),
      .r_empty(r_empty),
      .r_data(r_data)
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

  reg [7:0] val;

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
      val = val + 1;
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

    $finish;
  end

endmodule
