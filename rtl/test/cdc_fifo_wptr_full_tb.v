`include "testing.v"
`include "cdc_fifo_wptr_full.v"

module cdc_fifo_wptr_full_tb;

  parameter ADDR_SIZE = 4;

  reg                  w_clk;
  reg                  w_rst_n;
  reg                  w_inc;
  reg  [  ADDR_SIZE:0] w_q2_rptr;

  wire                 w_almost_full;
  wire                 w_full;
  wire [  ADDR_SIZE:0] w_ptr;
  wire [ADDR_SIZE-1:0] w_addr;

  cdc_fifo_wptr_full #(
      .ADDR_SIZE(ADDR_SIZE)
  ) uut (
      .w_clk        (w_clk),
      .w_rst_n      (w_rst_n),
      .w_inc        (w_inc),
      .w_q2_rptr    (w_q2_rptr),
      .w_almost_full(w_almost_full),
      .w_full       (w_full),
      .w_ptr        (w_ptr),
      .w_addr       (w_addr)
  );

  `TEST_SETUP(cdc_fifo_wptr_full_tb)

  initial begin
    w_clk = 0;
    forever #5 w_clk = ~w_clk;
  end

  initial begin
    w_rst_n   = 0;
    w_inc     = 0;
    w_q2_rptr = 0;
    @(posedge w_clk);

    w_rst_n = 1;
    @(posedge w_clk);

    // Test case 1: Basic increment
    repeat (4) begin
      w_inc = 1;
      @(posedge w_clk);
      w_inc = 0;
      @(posedge w_clk);
    end

    @(negedge w_clk);
    `ASSERT(w_ptr === 5'b00110)
    `ASSERT(w_addr === 4'b0100)

    @(posedge w_clk);

    // Test case 2: Full condition
    // (read ptr grey code for F)
    w_inc   = 0;
    w_rst_n = 0;
    @(posedge w_clk);
    w_rst_n = 1;
    @(negedge w_clk);

    repeat (15) begin
      w_inc = 1;
      @(posedge w_clk);
    end

    @(negedge w_clk);
    `ASSERT(w_almost_full === 1'b0)
    @(posedge w_clk);

    @(negedge w_clk);
    `ASSERT(w_almost_full === 1'b1)
    @(posedge w_clk);

    @(negedge w_clk);
    `ASSERT(w_almost_full === 1'b1)
    `ASSERT(w_full === 1'b1)
    `ASSERT(w_ptr === 5'b11000);
    `ASSERT(w_addr === 4'b0000);

    // Test case 3: Increment when full
    w_inc = 1;
    @(posedge w_clk);
    @(negedge w_clk);
    `ASSERT(w_full === 1'b1)
    `ASSERT(w_ptr === 5'b11000);
    `ASSERT(w_addr === 4'b0000);

    $finish;
  end

endmodule
