`include "testing.sv"
`include "axi_skidbuf.sv"

// We only do a basic smoke test because more thorough testing is
// done at the axis_skidbuf level.

module axi_skidbuf_tb;
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

  logic [AXI_ADDR_WIDTH-1:0] m_axi_araddr;
  logic                      m_axi_arvalid;
  logic                      m_axi_arready;
  logic [AXI_DATA_WIDTH-1:0] m_axi_rdata;
  logic [               1:0] m_axi_rresp;
  logic                      m_axi_rvalid;
  logic                      m_axi_rready;

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

  logic [AXI_ADDR_WIDTH-1:0] s_axi_araddr;
  logic                      s_axi_arvalid;
  logic                      s_axi_arready;
  logic [AXI_DATA_WIDTH-1:0] s_axi_rdata;
  logic [               1:0] s_axi_rresp;
  logic                      s_axi_rvalid;
  logic                      s_axi_rready;

  // verilator lint_off UNUSEDSIGNAL
  logic [               8:0] test_line;
  // verilator lint_on UNUSEDSIGNAL

  axi_skidbuf #(
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
      .s_axi_araddr (m_axi_araddr),
      .s_axi_arvalid(m_axi_arvalid),
      .s_axi_arready(m_axi_arready),
      .s_axi_rdata  (m_axi_rdata),
      .s_axi_rresp  (m_axi_rresp),
      .s_axi_rvalid (m_axi_rvalid),
      .s_axi_rready (m_axi_rready),
      .m_axi_awaddr (s_axi_awaddr),
      .m_axi_awvalid(s_axi_awvalid),
      .m_axi_awready(s_axi_awready),
      .m_axi_wdata  (s_axi_wdata),
      .m_axi_wstrb  (s_axi_wstrb),
      .m_axi_wvalid (s_axi_wvalid),
      .m_axi_wready (s_axi_wready),
      .m_axi_bresp  (s_axi_bresp),
      .m_axi_bvalid (s_axi_bvalid),
      .m_axi_bready (s_axi_bready),
      .m_axi_araddr (s_axi_araddr),
      .m_axi_arvalid(s_axi_arvalid),
      .m_axi_arready(s_axi_arready),
      .m_axi_rdata  (s_axi_rdata),
      .m_axi_rresp  (s_axi_rresp),
      .m_axi_rvalid (s_axi_rvalid),
      .m_axi_rready (s_axi_rready)
  );

  `TEST_SETUP(axi_skidbuf_tb)

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
    if (m_axi_arvalid && m_axi_arready) begin
      m_axi_arvalid <= 0;
    end
  end

  task setup();
    begin
      @(posedge axi_clk);
      axi_resetn    = 0;

      // Write channel signals
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

      // Read channel signals
      m_axi_araddr  = 0;
      m_axi_arvalid = 0;
      m_axi_rready  = 0;
      s_axi_arready = 0;
      s_axi_rvalid  = 0;
      s_axi_rdata   = 0;
      s_axi_rresp   = 0;

      @(posedge axi_clk);
      axi_resetn = 1;
      @(posedge axi_clk);
    end
  endtask

  task test_basic_write;
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
      m_axi_wstrb  = 2'b11;
      s_axi_wready = 1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_wvalid, 1'b1);
      `ASSERT_EQ(s_axi_wdata, 16'hABCD);
      `ASSERT_EQ(s_axi_wstrb, 2'b11);

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

  task test_basic_read;
    begin
      test_line = `__LINE__;
      setup();

      // Test address read path
      m_axi_arvalid = 1;
      m_axi_araddr  = 20'h54321;
      s_axi_arready = 1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_arvalid, 1'b1);
      `ASSERT_EQ(s_axi_araddr, 20'h54321);

      // Test data read path
      s_axi_rvalid = 1;
      s_axi_rdata  = 16'hDCBA;
      s_axi_rresp  = 2'b00;
      m_axi_rready = 1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(m_axi_rvalid, 1'b1);
      `ASSERT_EQ(m_axi_rdata, 16'hDCBA);
      `ASSERT_EQ(m_axi_rresp, 2'b00);
      `ASSERT_EQ(s_axi_rready, 1'b1);
    end
  endtask

  initial begin
    test_basic_write();
    test_basic_read();

    #100;
    $finish;
  end

endmodule
