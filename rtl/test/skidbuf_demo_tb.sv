`include "testing.sv"

`include "skidbuf_demo.sv"

module skidbuf_demo_tb;
  localparam DATA_BITS = 8;
  localparam NUM_PRE_SB = 16;
  localparam NUM_POST_SB = 16;
  localparam USE_SB = 1;

  logic                 clk;
  logic                 reset;

  logic [DATA_BITS-1:0] data_src;
  // verilator lint_off UNUSEDSIGNAL
  logic [DATA_BITS-1:0] data_dst;
  // verilator lint_on UNUSEDSIGNAL

  skidbuf_demo #(
      .DATA_BITS  (DATA_BITS),
      .NUM_PRE_SB (NUM_PRE_SB),
      .NUM_POST_SB(NUM_POST_SB),
      .USE_SB     (USE_SB)
  ) uut (
      .clk     (clk),
      .reset   (reset),
      .data_in (data_src),
      .data_out(data_dst)
  );

  `TEST_SETUP(skidbuf_demo_tb);

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  always @(posedge clk) begin
    if (reset) begin
      data_src <= 0;
    end else begin
      data_src <= data_src + 1;
    end
  end

  // Common setup task
  task setup();
    begin
      @(posedge clk);
      reset = 1;
      @(posedge clk);
      reset = 0;
      @(posedge clk);
    end
  endtask

  task test_basic;
    setup();

    repeat (128) begin
      @(posedge clk);
    end

    // The very first implementation of this checked the number we passed in,
    // but that was when the mid stages of the demo were just passing the data
    // along. That wasn't sufficient to causing timing issues, possibly due
    // to optimization. A counter was added to the mids that is added to the
    // data as it flows through, greatly increasing the combinatorial logic,
    // but also making it hard to predict the final value.
    //
    // there are 2 cycles of latency, plus 1 if we are using a skid buffer
    // `ASSERT_EQ(data_dst, 126 - USE_SB);
  endtask


  // Test sequence
  initial begin
    test_basic();

    #100;
    $finish;
  end

endmodule
