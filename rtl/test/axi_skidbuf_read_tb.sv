`include "testing.sv"
`include "axi_skidbuf_read.sv"

// We only do a basic smoke test because more thorough testing is
// done at the axis_skidbuf level.

module axi_skidbuf_read_tb;
  parameter AXI_ADDR_WIDTH = 20;
  parameter AXI_DATA_WIDTH = 16;

  logic                      axi_clk;
  logic                      axi_resetn;

  // These are from tb perspective
  logic [AXI_ADDR_WIDTH-1:0] m_axi_araddr;
  logic                      m_axi_arvalid;
  logic                      m_axi_arready;
  logic [AXI_DATA_WIDTH-1:0] m_axi_rdata;
  logic [               1:0] m_axi_rresp;
  logic                      m_axi_rvalid;
  logic                      m_axi_rready;

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

  axi_skidbuf_read #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) uut (
      .axi_clk      (axi_clk),
      .axi_resetn   (axi_resetn),
      .s_axi_araddr (m_axi_araddr),
      .s_axi_arvalid(m_axi_arvalid),
      .s_axi_arready(m_axi_arready),
      .s_axi_rdata  (m_axi_rdata),
      .s_axi_rresp  (m_axi_rresp),
      .s_axi_rvalid (m_axi_rvalid),
      .s_axi_rready (m_axi_rready),
      .m_axi_araddr (s_axi_araddr),
      .m_axi_arvalid(s_axi_arvalid),
      .m_axi_arready(s_axi_arready),
      .m_axi_rdata  (s_axi_rdata),
      .m_axi_rresp  (s_axi_rresp),
      .m_axi_rvalid (s_axi_rvalid),
      .m_axi_rready (s_axi_rready)
  );

  `TEST_SETUP(axi_skidbuf_read_tb)

  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  // Auto-lower valid signal after successful handshake
  always @(posedge axi_clk) begin
    if (m_axi_arvalid && m_axi_arready) begin
      m_axi_arvalid <= 0;
    end
  end

  task setup();
    begin
      @(posedge axi_clk);
      axi_resetn    = 0;
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

  // Basic smoke test
  task test_basic_flow;
    begin
      test_line = `__LINE__;
      setup();

      // Test address read path
      m_axi_arvalid = 1;
      m_axi_araddr  = 20'h12345;
      s_axi_arready = 1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_arvalid, 1'b1);
      `ASSERT_EQ(s_axi_araddr, 20'h12345);

      // Test data read path
      s_axi_rvalid = 1;
      s_axi_rdata  = 16'hABCD;
      s_axi_rresp  = 2'b00;
      m_axi_rready = 1;
      `ASSERT_EQ(s_axi_rready, 1'b1);

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(m_axi_rvalid, 1'b1);
      `ASSERT_EQ(m_axi_rdata, 16'hABCD);
      `ASSERT_EQ(m_axi_rresp, 2'b00);
    end
  endtask

  initial begin
    test_basic_flow();

    #100;
    $finish;
  end

endmodule