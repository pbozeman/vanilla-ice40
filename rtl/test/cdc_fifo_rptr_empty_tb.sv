`include "testing.sv"

`include "cdc_fifo_rptr_empty.sv"

module cdc_fifo_rptr_empty_tb;

  parameter ADDR_SIZE = 4;

  reg                  r_clk;
  reg                  r_rst_n;
  reg                  r_inc;
  reg  [  ADDR_SIZE:0] r_q2_wptr;

  wire                 r_empty;
  wire [  ADDR_SIZE:0] r_ptr;
  wire [ADDR_SIZE-1:0] r_addr;

  `TEST_SETUP(cdc_fifo_rptr_empty_tb)

  cdc_fifo_rptr_empty #(
      .ADDR_SIZE(ADDR_SIZE)
  ) uut (
      .r_clk    (r_clk),
      .r_rst_n  (r_rst_n),
      .r_inc    (r_inc),
      .r_q2_wptr(r_q2_wptr),
      .r_empty  (r_empty),
      .r_ptr    (r_ptr),
      .r_addr   (r_addr)
  );

  initial begin
    r_clk = 0;
    forever #5 r_clk = ~r_clk;
  end

  initial begin
    r_rst_n   = 0;
    r_inc     = 0;
    r_q2_wptr = 0;
    @(posedge r_clk);
    @(negedge r_clk);

    r_rst_n = 1;
    @(posedge r_clk);

    // Test initial state
    `ASSERT(r_empty === 1'b1);
    `ASSERT(r_ptr === 5'b00000);
    `ASSERT(r_addr === 4'b0000);

    // Simulate a writer
    r_q2_wptr = 5'b00001;
    @(posedge r_clk);
    `ASSERT(r_empty === 1'b0);

    // Test incrementing
    r_inc = 1;
    @(posedge r_clk);
    @(negedge r_clk);
    `ASSERT(r_empty === 1'b1);
    `ASSERT(r_ptr === 5'b00001);
    `ASSERT(r_addr === 4'b0001);

    // Test multiple increments
    r_q2_wptr = 5'b00110;
    repeat (4) @(posedge r_clk);
    @(negedge r_clk);
    `ASSERT(r_ptr === 5'b00110);
    `ASSERT(r_addr === 4'b0100);

    // Test wrap-around
    r_q2_wptr = 5'b11001;
    repeat (16) @(posedge r_clk);
    `ASSERT(r_ptr === 5'b11001);
    `ASSERT(r_addr === 4'b0001);

    $finish;
  end

endmodule
