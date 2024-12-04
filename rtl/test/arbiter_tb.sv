`include "testing.sv"
`include "arbiter.sv"

module arbiter_tb;
  localparam NUM_M = 3;
  localparam G_BITS = $clog2(NUM_M + 1);

  logic              clk;
  logic              rst_n;
  logic [ NUM_M-1:0] g_want;
  logic              req_accepted;
  logic              resp_accepted;
  logic [G_BITS-1:0] g_req;
  logic [G_BITS-1:0] g_resp;

  // verilator lint_off UNUSEDSIGNAL
  logic [       8:0] test_line;
  // verilator lint_on UNUSEDSIGNAL

  arbiter #(
      .NUM_M(NUM_M)
  ) uut (
      .clk,
      .rst_n,
      .g_want,
      .req_accepted(req_accepted),
      .resp_accepted,
      .g_req,
      .g_resp
  );

  `TEST_SETUP(arbiter_tb)

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  task setup();
    begin
      @(posedge clk);
      rst_n         = 0;
      g_want        = '0;
      req_accepted  = 0;
      resp_accepted = 0;
      @(posedge clk);
      rst_n = 1;
      @(posedge clk);
    end
  endtask

  task test_single_manager();
    begin
      test_line = `__LINE__;
      setup();

      // Request from manager 0
      g_want = 3'b001;
      @(posedge clk);
      g_want       = 3'b000;
      req_accepted = 1;

      #1;
      `ASSERT_EQ(g_req, 0);

      // response grant
      @(posedge clk);
      req_accepted  = 0;
      resp_accepted = 1;

      #1;
      `ASSERT_EQ(g_resp, 0);

      // Verify grants cleared
      `TICK(clk);
      resp_accepted = 0;

      #1;
      `ASSERT_EQ(g_req, NUM_M);
      `ASSERT_EQ(g_resp, NUM_M);
    end
  endtask

  task test_priority();
    begin
      test_line = `__LINE__;
      setup();

      // Request from all managers
      // Verify highest priority (lowest index) gets grant
      g_want = 3'b111;

      @(posedge clk);
      req_accepted = 1;
      g_want       = 3'b110;

      #1;
      `ASSERT_EQ(g_req, 0);

      // Accept request
      @(posedge clk);
      req_accepted = 0;

      #1;
      `ASSERT_EQ(g_req, 1);
    end
  endtask

  task test_pipelining();
    begin
      test_line = `__LINE__;
      setup();

      // Initial request
      g_want = 3'b001;

      @(posedge clk);
      req_accepted = 1;

      #1;
      `ASSERT_EQ(g_req, 0);

      @(posedge clk);
      req_accepted = 0;

      #1;
      `ASSERT_EQ(g_req, NUM_M);
      `ASSERT_EQ(g_resp, 0);

      // Complete transaction
      resp_accepted = 1;
      resp_accepted = 0;

      @(posedge clk);

      #1;
      `ASSERT_EQ(g_req, 0);
      `ASSERT_EQ(g_resp, 0);
    end
  endtask

  initial begin
    test_single_manager();
    test_priority();
    test_pipelining();
    #100;

    $finish;
  end

endmodule
