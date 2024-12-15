`include "testing.sv"
`include "axi_skidbuf_write.sv"

// We only do a basic smoke test because more thorough testing is
// done at the axis_skidbuf level.

module axi_skidbuf_write_tb;
  parameter AXI_ADDR_WIDTH = 20;
  parameter AXI_DATA_WIDTH = 16;
  localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8;

  logic                      axi_clk;
  logic                      axi_resetn;

  // These are from tb perspective
  logic [AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
  logic                      m_axi_awvalid;
  logic                      m_axi_awready;
  logic [AXI_DATA_WIDTH-1:0] m_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] m_axi_wstrb;
  logic                      m_axi_wvalid;
  logic                      m_axi_wready;
  logic [               1:0] m_axi_bresp;
  logic                      m_axi_bvalid;
  logic                      m_axi_bready;

  logic [AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
  logic                      s_axi_awvalid;
  logic                      s_axi_awready;
  logic [AXI_DATA_WIDTH-1:0] s_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] s_axi_wstrb;
  logic                      s_axi_wvalid;
  logic                      s_axi_wready;
  logic [               1:0] s_axi_bresp;
  logic                      s_axi_bvalid;
  logic                      s_axi_bready;

  // verilator lint_off UNUSEDSIGNAL
  logic [               8:0] test_line;
  // verilator lint_on UNUSEDSIGNAL

  axi_skidbuf_write #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) uut (
      .axi_clk      (axi_clk),
      .axi_resetn   (axi_resetn),
      .s_axi_awaddr (m_axi_awaddr),
      .s_axi_awvalid(m_axi_awvalid),
      .s_axi_awready(m_axi_awready),
      .s_axi_wdata  (m_axi_wdata),
      .s_axi_wstrb  (m_axi_wstrb),
      .s_axi_wvalid (m_axi_wvalid),
      .s_axi_wready (m_axi_wready),
      .s_axi_bresp  (m_axi_bresp),
      .s_axi_bvalid (m_axi_bvalid),
      .s_axi_bready (m_axi_bready),
      .m_axi_awaddr (s_axi_awaddr),
      .m_axi_awvalid(s_axi_awvalid),
      .m_axi_awready(s_axi_awready),
      .m_axi_wdata  (s_axi_wdata),
      .m_axi_wstrb  (s_axi_wstrb),
      .m_axi_wvalid (s_axi_wvalid),
      .m_axi_wready (s_axi_wready),
      .m_axi_bresp  (s_axi_bresp),
      .m_axi_bvalid (s_axi_bvalid),
      .m_axi_bready (s_axi_bready)
  );

  `TEST_SETUP(axi_skidbuf_write_tb)

  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  // Auto-lower valid signals after successful handshake
  always @(posedge axi_clk) begin
    if (m_axi_awvalid && m_axi_awready) begin
      m_axi_awvalid <= 0;
    end
    if (m_axi_wvalid && m_axi_wready) begin
      m_axi_wvalid <= 0;
    end
  end

  task setup();
    begin
      @(posedge axi_clk);
      axi_resetn    = 0;
      m_axi_awaddr  = 0;
      m_axi_awvalid = 0;
      m_axi_wdata   = 0;
      m_axi_wstrb   = 0;
      m_axi_wvalid  = 0;
      m_axi_bready  = 0;
      s_axi_awready = 0;
      s_axi_wready  = 0;
      s_axi_bvalid  = 0;
      s_axi_bresp   = 0;
      @(posedge axi_clk);
      axi_resetn = 1;
      @(posedge axi_clk);
    end
  endtask

  task test_basic_flow;
    begin
      test_line = `__LINE__;
      setup();

      // Test address write path
      m_axi_awvalid = 1;
      m_axi_awaddr  = 20'h12345;
      s_axi_awready = 1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_awvalid, 1'b1);
      `ASSERT_EQ(s_axi_awaddr, 20'h12345);

      // Test data write path
      m_axi_wvalid = 1;
      m_axi_wdata  = 16'hABCD;
      s_axi_wready = 1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_wvalid, 1'b1);
      `ASSERT_EQ(s_axi_wdata, 16'hABCD);
      `ASSERT_EQ(s_axi_wstrb, '0);

      // Test write response path
      s_axi_bvalid = 1;
      s_axi_bresp  = 2'b00;
      m_axi_bready = 1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(m_axi_bvalid, 1'b1);
      `ASSERT_EQ(m_axi_bresp, 2'b00);
      `ASSERT_EQ(s_axi_bready, 1'b1);
    end
  endtask

  initial begin
    test_basic_flow();

    #100;
    $finish;
  end

endmodule
