`include "testing.sv"
`include "iter.sv"

module iter_tb;
  logic       clk;
  logic       init;
  logic [3:0] init_val;
  logic [3:0] max_val;
  logic       inc;
  logic [3:0] val;
  logic       last;

  iter uut (.*);

  `TEST_SETUP(iter_tb)
  // verilator lint_off UNUSEDSIGNAL
  logic [8:0] test_line;
  // verilator lint_on UNUSEDSIGNAL

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  task setup;
    begin
      @(posedge clk);
      init     = 0;
      init_val = 0;
      max_val  = 0;
      inc      = 0;

      @(posedge clk);
      #1;
    end
  endtask

  // Test simple iteration from 0 to 3
  task test_basic_iter;
    begin
      test_line = `__LINE__;
      setup();

      // Initialize to 0, count to 3
      init     = 1;
      init_val = 0;
      max_val  = 3;
      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 0);
      `ASSERT_EQ(last, 0);

      init = 0;
      inc  = 1;
      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 1);
      `ASSERT_EQ(last, 0);

      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 2);
      `ASSERT_EQ(last, 0);

      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 3);
      `ASSERT_EQ(last, 1);

      // Should stay at max
      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 3);
      `ASSERT_EQ(last, 1);
    end
  endtask

  // Test pausing iteration by controlling inc
  task test_paused_iter;
    begin
      test_line = `__LINE__;
      setup();

      // Initialize to 0, count to 3 with pauses
      init     = 1;
      init_val = 0;
      max_val  = 3;
      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 0);

      init = 0;
      inc  = 1;
      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 1);

      // Pause for a cycle
      inc = 0;
      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 1);

      // Resume
      inc = 1;
      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 2);
    end
  endtask

  // Test mid-range initialization
  task test_init_mid;
    begin
      test_line = `__LINE__;
      setup();

      // Start at 2, count to 5
      init     = 1;
      init_val = 2;
      max_val  = 5;
      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 2);
      `ASSERT_EQ(last, 0);

      init = 0;
      inc  = 1;
      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 3);
      `ASSERT_EQ(last, 0);

      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 4);
      `ASSERT_EQ(last, 0);

      @(posedge clk);
      #1;
      `ASSERT_EQ(val, 5);
      `ASSERT_EQ(last, 1);
    end
  endtask

  // Test sequence
  initial begin
    test_basic_iter();
    test_paused_iter();
    test_init_mid();

    $finish;
  end

endmodule
