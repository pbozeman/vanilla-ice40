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
  // verilator lint_off UNUSEDSIGNAL
  // TODO: add almost full tests
  logic                  w_almost_full;
  // verilator lint_on UNUSEDSIGNAL
  logic                  r_inc;
  logic                  r_empty;
  logic [DATA_WIDTH-1:0] r_data;

  sync_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_SIZE (ADDR_SIZE)
  ) uut (
      .clk          (clk),
      .rst_n        (rst_n),
      .w_inc        (w_inc),
      .w_data       (w_data),
      .w_full       (w_full),
      .w_almost_full(w_almost_full),
      .r_inc        (r_inc),
      .r_empty      (r_empty),
      .r_data       (r_data)
  );

  `TEST_SETUP(sync_fifo_tb)

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  task reset_test;
    begin
      @(posedge clk);
      rst_n = 0;
      @(posedge clk);

      w_inc  = 0;
      w_data = 0;
      r_inc  = 0;

      @(posedge clk);
      rst_n = 1;
      @(posedge clk);
    end
  endtask

  task test_post_reset;
    reset_test();

    `ASSERT(r_empty === 1'b1)
    `ASSERT(w_full === 1'b0)
  endtask

  task test_single_write_read;
    reset_test();

    // write
    w_data = 8'hA5;
    w_inc  = 1;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(r_empty === 1'b0)
    `ASSERT_EQ(r_data, 8'hA5)
    w_inc = 0;

    // read
    r_inc = 1;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(r_empty === 1'b1)
  endtask

  task test_fill_fifo;
    reset_test();

    for (int i = 0; i < DEPTH; i++) begin
      w_data = i[DATA_WIDTH-1:0];
      w_inc  = 1;
      @(posedge clk);
      @(negedge clk);
      `ASSERT_EQ(w_full, (i == DEPTH - 1));
    end

    w_inc = 0;
    `ASSERT(w_full);
  endtask

  task test_read_full_fifo;
    reset_test();
    test_fill_fifo();

    for (int i = 0; i < DEPTH; i++) begin
      `ASSERT_EQ(r_data, i);
      r_inc = 1;
      @(posedge clk);
      @(negedge clk);
      `ASSERT_EQ(r_empty, (i == DEPTH - 1));
    end

    r_inc = 0;
    `ASSERT(r_empty);
  endtask

  // Test stimulus
  initial begin
    test_post_reset();
    test_single_write_read();
    test_fill_fifo();
    test_read_full_fifo();

    $finish;
  end
endmodule
