`include "testing.sv"
`include "counter.sv"

module counter_tb;
  logic       clk;
  logic       reset;
  logic       enable;
  logic [7:0] count;

  counter #(
      .WIDTH(8)
  ) uut (
      .clk   (clk),
      .reset (reset),
      .enable(enable),
      .count (count)
  );

  `TEST_SETUP(counter_tb)
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
      reset  = 1;
      enable = 0;
      @(posedge clk);
      reset = 0;
    end
  endtask

  task test_basic_counting;
    begin
      test_line = `__LINE__;
      setup();

      enable = 1;
      @(posedge clk);
      #1;
      `ASSERT_EQ(count, 8'h01);

      @(posedge clk);
      #1;
      `ASSERT_EQ(count, 8'h02);

      @(posedge clk);
      #1;
      `ASSERT_EQ(count, 8'h03);

      enable = 0;
      @(posedge clk);
      #1;
      `ASSERT_EQ(count, 8'h03);
    end
  endtask

  task test_reset;
    begin
      test_line = `__LINE__;
      setup();

      enable = 1;
      @(posedge clk);
      @(posedge clk);
      #1;
      `ASSERT_EQ(count, 8'h02);

      reset = 1;
      @(posedge clk);
      #1;
      `ASSERT_EQ(count, 8'h00);
    end
  endtask

  task test_enable_toggle;
    begin
      test_line = `__LINE__;
      setup();

      enable = 1;
      @(posedge clk);
      #1;
      `ASSERT_EQ(count, 8'h01);

      enable = 0;
      @(posedge clk);
      #1;
      `ASSERT_EQ(count, 8'h01);

      enable = 1;
      @(posedge clk);
      #1;
      `ASSERT_EQ(count, 8'h02);
    end
  endtask

  initial begin
    test_basic_counting();
    test_reset();
    test_enable_toggle();

    $finish;
  end

endmodule
