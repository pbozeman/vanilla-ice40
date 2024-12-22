`include "testing.sv"

`include "axis_fifobuf.sv"

module axis_fifobuf_tb;
  parameter DATA_WIDTH = 8;
  parameter FIFO_ADDR_SIZE = 4;
  parameter FIFO_ALMOST_FULL_BUF = 4;
  parameter MAX_WRITE = (1 << FIFO_ADDR_SIZE) - FIFO_ALMOST_FULL_BUF;

  logic                  axi_clk;
  logic                  axi_resetn = 0;
  logic                  m_axi_tvalid;
  logic                  m_axi_tready;
  logic [DATA_WIDTH-1:0] m_axi_tdata;
  logic                  s_axi_tvalid;
  logic                  s_axi_tready;
  logic [DATA_WIDTH-1:0] s_axi_tdata;

  // verilator lint_off UNUSEDSIGNAL
  logic [           8:0] test_line;
  // verilator lint_on UNUSEDSIGNAL

  // Clock generation
  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  axis_fifobuf #(
      .DATA_WIDTH          (DATA_WIDTH),
      .FIFO_ADDR_SIZE      (FIFO_ADDR_SIZE),
      .FIFO_ALMOST_FULL_BUF(FIFO_ALMOST_FULL_BUF)
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

  `TEST_SETUP(axis_fifobuf_tb)

  task setup();
    begin
      axi_resetn   = 0;
      m_axi_tvalid = 0;
      m_axi_tdata  = 0;
      s_axi_tready = 0;
      @(posedge axi_clk);
      axi_resetn = 1;
      @(posedge axi_clk);
    end
  endtask

  task test_basic;
    begin
      test_line = `__LINE__;
      setup();

      `ASSERT_EQ(s_axi_tvalid, 1'b0);
      m_axi_tvalid = 1;
      m_axi_tdata  = 8'hA1;

      `ASSERT_EQ(m_axi_tready, 1'b1);
      @(posedge axi_clk);
      #1;
      m_axi_tvalid = 0;

      `ASSERT_EQ(m_axi_tready, 1'b1);
      `ASSERT_EQ(s_axi_tvalid, 1'b1);
      `ASSERT_EQ(s_axi_tdata, 8'hA1);

      // we haven't done a s_axi_tready yet
      @(posedge axi_clk);
      s_axi_tready = 1;
      #1;
      `ASSERT_EQ(m_axi_tready, 1'b1);
      `ASSERT_EQ(s_axi_tvalid, 1'b1);
      `ASSERT_EQ(s_axi_tdata, 8'hA1);

      // now we should be back to empty
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(m_axi_tready, 1'b1);
      `ASSERT_EQ(s_axi_tvalid, 1'b0);
    end
  endtask

  task test_multi;
    begin
      test_line = `__LINE__;
      setup();

      m_axi_tvalid = 1;
      for (int i = 0; i < MAX_WRITE; i++) begin
        m_axi_tdata = 8'hA0 + DATA_WIDTH'(i);
        @(posedge axi_clk);

        #1;
        `ASSERT_EQ(m_axi_tready, 1'b1);
      end
      m_axi_tvalid = 0;

      `ASSERT_EQ(m_axi_tready, 1'b1);
      m_axi_tdata = 8'hB0;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(m_axi_tready, 1'b0);

      // let the data flow
      s_axi_tready = 1;
      `ASSERT_EQ(s_axi_tvalid, 1'b1);
      `ASSERT_EQ(s_axi_tdata, 8'hA0);
      `ASSERT_EQ(m_axi_tready, 1'b0);

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_tvalid, 1'b1);
      `ASSERT_EQ(s_axi_tdata, 8'hA1);

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_tvalid, 1'b1);
      `ASSERT_EQ(s_axi_tdata, 8'hA2);

      `ASSERT_EQ(m_axi_tready, 1'b1);
    end
  endtask

  // Test sequence
  initial begin
    test_basic();
    test_multi();

    #100;
    $finish;
  end
endmodule
