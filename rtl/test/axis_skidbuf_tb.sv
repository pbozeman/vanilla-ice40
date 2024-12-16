`include "testing.sv"

`include "axis_skidbuf.sv"

module axis_skidbuf_tb;
  parameter DATA_BITS = 8;

  logic                 axi_clk;
  logic                 axi_resetn;

  // these are from the tb's perspective, not the skid buf
  logic                 s_axi_tvalid;
  logic                 s_axi_tready;
  logic [DATA_BITS-1:0] s_axi_tdata;

  logic                 m_axi_tvalid;
  logic                 m_axi_tready;
  logic [DATA_BITS-1:0] m_axi_tdata;

  // verilator lint_off UNUSEDSIGNAL
  logic [          8:0] test_line;
  // verilator lint_on UNUSEDSIGNAL
  //
  axis_skidbuf #(
      .DATA_BITS(DATA_BITS)
  ) uut (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .s_axi_tvalid(m_axi_tvalid),
      .s_axi_tready(m_axi_tready),
      .s_axi_tdata (m_axi_tdata),
      .m_axi_tvalid(s_axi_tvalid),
      .m_axi_tready(s_axi_tready),
      .m_axi_tdata (s_axi_tdata)
  );

  `TEST_SETUP(axis_skidbuf_tb)

  // Clock generation
  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  always @(posedge axi_clk) begin
    if (m_axi_tvalid && m_axi_tready) begin
      m_axi_tvalid <= 0;
    end
  end

  task setup();
    begin
      @(posedge axi_clk);
      axi_resetn   = 0;
      m_axi_tvalid = 0;
      m_axi_tdata  = 0;
      s_axi_tready = 0;
      @(posedge axi_clk);

      axi_resetn = 1;
      @(posedge axi_clk);
    end
  endtask

  // Test basic data flow
  task test_basic_flow;
    begin
      test_line = `__LINE__;
      setup();

      s_axi_tready = 1;
      m_axi_tvalid = 1;
      m_axi_tdata  = 8'hA5;
      @(posedge axi_clk);

      #1;
      `ASSERT_EQ(s_axi_tdata, 8'hA5);
      `ASSERT_EQ(s_axi_tvalid, 1'b1);

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_tvalid, 1'b0);
    end
  endtask

  // Test back pressure handling
  task test_backpressure;
    begin
      test_line = `__LINE__;
      setup();

      s_axi_tready = 0;
      m_axi_tvalid = 1;
      m_axi_tdata  = 8'h55;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_tdata, 8'h55);
      `ASSERT_EQ(s_axi_tvalid, 1'b1);
      `ASSERT_EQ(m_axi_tready, 1'b1);

      m_axi_tvalid = 1;
      m_axi_tdata  = 8'hAA;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_tdata, 8'h55);

      s_axi_tready = 1;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_tdata, 8'hAA);
      `ASSERT_EQ(s_axi_tvalid, 1'b1);
    end
  endtask

  // Test continuous data flow
  task test_continuoum_flow;
    begin
      test_line = `__LINE__;
      setup();

      s_axi_tready = 1;

      for (int i = 0; i < 4; i++) begin
        m_axi_tvalid = 1;
        m_axi_tdata  = DATA_BITS'(i);
        @(posedge axi_clk);
        #1;
        `ASSERT_EQ(s_axi_tdata, DATA_BITS'(i));
      end
    end
  endtask

  // Test reset behavior
  task test_reset;
    begin
      test_line = `__LINE__;
      setup();

      s_axi_tready = 0;
      m_axi_tvalid = 1;
      m_axi_tdata  = 8'h42;
      @(posedge axi_clk);
      #1;

      axi_resetn = 0;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_tvalid, 1'b0);
      `ASSERT_EQ(m_axi_tready, 1'b1);
    end
  endtask

  initial begin
    test_basic_flow();
    test_backpressure();
    test_continuoum_flow();
    test_reset();

    #100;
    $finish;
  end

endmodule
