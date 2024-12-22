`include "testing.sv"

`include "axi_stripe_writer.sv"
`include "axi_sram_controller.sv"
`include "sram_model.sv"

// verilator lint_off UNUSEDSIGNAL
module axi_stripe_writer_tb;
  localparam NUM_S = 2;
  localparam AXI_ADDR_WIDTH = 20;
  localparam AXI_DATA_WIDTH = 16;
  localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8;

  logic                                          axi_clk;
  logic                                          axi_resetn = 1'b0;

  logic [AXI_ADDR_WIDTH-1:0]                     m_axi_awaddr;
  logic                                          m_axi_awvalid;
  logic                                          m_axi_awready;
  logic [AXI_DATA_WIDTH-1:0]                     m_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0]                     m_axi_wstrb;
  logic                                          m_axi_wvalid;
  logic                                          m_axi_wready;
  logic [               1:0]                     m_axi_bresp;
  logic                                          m_axi_bvalid;
  logic                                          m_axi_bready;
  logic [AXI_ADDR_WIDTH-1:0]                     m_axi_araddr;
  logic                                          m_axi_arvalid;
  logic                                          m_axi_arready;
  logic [AXI_DATA_WIDTH-1:0]                     m_axi_rdata;
  logic [               1:0]                     m_axi_rresp;
  logic                                          m_axi_rvalid;
  logic                                          m_axi_rready;

  // Output AXI interface
  logic [         NUM_S-1:0][AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
  logic [         NUM_S-1:0]                     s_axi_awvalid;
  logic [         NUM_S-1:0]                     s_axi_awready;
  logic [         NUM_S-1:0][AXI_DATA_WIDTH-1:0] s_axi_wdata;
  logic [         NUM_S-1:0][AXI_STRB_WIDTH-1:0] s_axi_wstrb;
  logic [         NUM_S-1:0]                     s_axi_wvalid;
  logic [         NUM_S-1:0]                     s_axi_wready;
  logic [         NUM_S-1:0][               1:0] s_axi_bresp;
  logic [         NUM_S-1:0]                     s_axi_bvalid;
  logic [         NUM_S-1:0]                     s_axi_bready;
  logic [         NUM_S-1:0][AXI_ADDR_WIDTH-1:0] s_axi_araddr = '0;
  logic [         NUM_S-1:0]                     s_axi_arvalid = '0;
  logic [         NUM_S-1:0]                     s_axi_arready;
  logic [         NUM_S-1:0][AXI_DATA_WIDTH-1:0] s_axi_rdata;
  logic [         NUM_S-1:0][               1:0] s_axi_rresp;
  logic [         NUM_S-1:0]                     s_axi_rvalid;
  logic [         NUM_S-1:0]                     s_axi_rready = '0;

  // SRAM
  logic [         NUM_S-1:0][AXI_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [         NUM_S-1:0][AXI_DATA_WIDTH-1:0] sram_io_data;
  logic [         NUM_S-1:0]                     sram_io_we_n;
  logic [         NUM_S-1:0]                     sram_io_oe_n;
  logic [         NUM_S-1:0]                     sram_io_ce_n;

  logic                                          in_write_accepted;

  axi_stripe_writer #(
      .NUM_S         (NUM_S),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) uut (
      .axi_clk   (axi_clk),
      .axi_resetn(axi_resetn),

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

  for (genvar i = 0; i < NUM_S; i++) begin : gen_s_modules
    sram_model #(
        .ADDR_BITS                (AXI_ADDR_WIDTH),
        .DATA_BITS                (AXI_DATA_WIDTH),
        .UNINITIALIZED_READS_FATAL(0)
    ) sram_model_i (
        .reset  (~axi_resetn),
        .we_n   (sram_io_we_n[i]),
        .oe_n   (sram_io_oe_n[i]),
        .ce_n   (sram_io_ce_n[i]),
        .addr   (sram_io_addr[i]),
        .data_io(sram_io_data[i])
    );

    axi_sram_controller #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi_sram_ctrl_i (
        .axi_clk     (axi_clk),
        .axi_resetn  (axi_resetn),
        .axi_awaddr  (s_axi_awaddr[i]),
        .axi_awvalid (s_axi_awvalid[i]),
        .axi_awready (s_axi_awready[i]),
        .axi_wdata   (s_axi_wdata[i]),
        .axi_wstrb   (s_axi_wstrb[i]),
        .axi_wvalid  (s_axi_wvalid[i]),
        .axi_wready  (s_axi_wready[i]),
        .axi_bresp   (s_axi_bresp[i]),
        .axi_bvalid  (s_axi_bvalid[i]),
        .axi_bready  (s_axi_bready[i]),
        .axi_araddr  (s_axi_araddr[i]),
        .axi_arvalid (s_axi_arvalid[i]),
        .axi_arready (s_axi_arready[i]),
        .axi_rdata   (s_axi_rdata[i]),
        .axi_rresp   (s_axi_rresp[i]),
        .axi_rvalid  (s_axi_rvalid[i]),
        .axi_rready  (s_axi_rready[i]),
        .sram_io_addr(sram_io_addr[i]),
        .sram_io_data(sram_io_data[i]),
        .sram_io_we_n(sram_io_we_n[i]),
        .sram_io_oe_n(sram_io_oe_n[i]),
        .sram_io_ce_n(sram_io_ce_n[i])
    );
  end

  // auto clear manager valid flags
  always @(posedge axi_clk) begin
    if (m_axi_awvalid && m_axi_awready) begin
      m_axi_awvalid <= 0;
    end

    if (m_axi_wvalid && m_axi_wready) begin
      m_axi_wvalid <= 0;
    end
  end

  assign in_write_accepted = (m_axi_awvalid && m_axi_awready && m_axi_wvalid &&
                              m_axi_wready);


  `TEST_SETUP(axi_stripe_writer_tb);
  logic [8:0] test_line;

  // Clock generation
  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  // Common test setup
  task setup();
    begin
      @(posedge axi_clk);
      axi_resetn    = 0;

      // Reset all input signals
      m_axi_awaddr  = '0;
      m_axi_awvalid = '0;
      m_axi_wdata   = '0;
      m_axi_wstrb   = '0;
      m_axi_wvalid  = '0;
      m_axi_bready  = '0;
      m_axi_araddr  = '0;
      m_axi_arvalid = '0;
      m_axi_rready  = '0;

      @(posedge axi_clk);
      axi_resetn = 1;
      @(posedge axi_clk);
    end
  endtask

  task test_awaddr_even;
    begin
      test_line = `__LINE__;
      setup();

      `ASSERT_EQ(uut.req, '1);

      m_axi_awvalid = 1'b1;
      m_axi_awaddr  = 20'h1000;
      m_axi_wvalid  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.req, 0);
      `ASSERT_EQ(s_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(s_axi_awaddr[0], 20'h1000);

      setup();
      m_axi_awvalid = 1'b1;
      m_axi_awaddr  = 20'h2001;
      m_axi_wvalid  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.req, 1);
      `ASSERT_EQ(s_axi_awvalid[1], 1'b1);
      `ASSERT_EQ(s_axi_awaddr[1], 20'h2001);
    end
  endtask

  task test_write_mux_even;
    begin
      test_line = `__LINE__;
      setup();

      m_axi_awaddr  = 20'h1000;
      m_axi_awvalid = 1'b1;
      m_axi_wdata   = 16'hDEAD;
      m_axi_wstrb   = 2'b10;
      m_axi_wvalid  = 1'b1;
      m_axi_bready  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.req, 0);
      `ASSERT_EQ(s_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(s_axi_awaddr[0], 20'h1000);
      `ASSERT_EQ(s_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(s_axi_wdata[0], 16'hDEAD);
      `ASSERT_EQ(s_axi_wvalid[0], 1'b1);
      `ASSERT_EQ(s_axi_wstrb[0], 2'b10);

      `ASSERT_EQ(s_axi_bready[0], 1'b0);
      `WAIT_FOR_SIGNAL(in_write_accepted);

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(s_axi_bready[0], 1'b1);
    end
  endtask

  task test_write_even;
    begin
      test_line = `__LINE__;
      setup();

      m_axi_awaddr  = 20'h1000;
      m_axi_awvalid = 1'b1;
      m_axi_wdata   = 16'hDEAD;
      m_axi_wstrb   = 2'b10;
      m_axi_wvalid  = 1'b1;
      m_axi_bready  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(m_axi_awvalid, 1'b1);
      `ASSERT_EQ(m_axi_awready, 1'b1);
      `ASSERT_EQ(m_axi_wvalid, 1'b1);
      `ASSERT_EQ(m_axi_wready, 1'b1);

      `WAIT_FOR_SIGNAL(m_axi_bvalid);
    end
  endtask

  task test_write_even_pipeline;
    begin
      test_line = `__LINE__;
      setup();

      // First write to even
      m_axi_awaddr  = 20'h1000;
      m_axi_awvalid = 1'b1;
      m_axi_wdata   = 16'hDEAD;
      m_axi_wstrb   = 2'b11;
      m_axi_wvalid  = 1'b1;
      m_axi_bready  = 1'b1;

      @(posedge axi_clk);
      // Check first transaction signals
      #1;
      `ASSERT_EQ(uut.req, 0);
      `ASSERT_EQ(s_axi_awaddr[0], 20'h1000);
      `ASSERT_EQ(s_axi_wdata[0], 16'hDEAD);

      // second write while first is in flight
      m_axi_awaddr  = 20'h2000;
      m_axi_awvalid = 1'b1;
      m_axi_wdata   = 16'hBEEF;
      m_axi_wstrb   = 2'b11;
      m_axi_wvalid  = 1'b1;
      m_axi_bready  = 1'b1;

      `WAIT_FOR_SIGNAL(in_write_accepted);

      // Check second transaction grant and signals.
      #1;
      `ASSERT_EQ(uut.req, 0);
      `ASSERT_EQ(s_axi_awaddr[0], 20'h2000);
      `ASSERT_EQ(s_axi_wdata[0], 16'hBEEF);

      // Wait for B channel to complete
      `WAIT_FOR_SIGNAL(m_axi_bvalid);
    end
  endtask

  task test_write_sequential_pipeline;
    begin
      test_line = `__LINE__;
      setup();

      @(posedge axi_clk);
      for (int i = 0; i < 32; i++) begin
        @(posedge axi_clk);
        m_axi_awaddr  = 20'(i);
        m_axi_awvalid = 1'b1;
        m_axi_wdata   = 16'hD000 + 16'(i);
        m_axi_wstrb   = 2'b11;
        m_axi_wvalid  = 1'b1;
        m_axi_bready  = 1'b1;

        `WAIT_FOR_SIGNAL(in_write_accepted);

        if (i % 2 == 0) begin
          `ASSERT_EQ(uut.req_full, 0);
          `ASSERT_EQ(s_axi_awaddr[0], 20'(i));
          `ASSERT_EQ(s_axi_wdata[0], 16'hD000 + 16'(i));
        end else begin
          `ASSERT_EQ(uut.req_full, 1);
          `ASSERT_EQ(s_axi_awaddr[1], 20'(i));
          `ASSERT_EQ(s_axi_wdata[1], 16'hD000 + 16'(i));
        end

      end
    end
  endtask

  initial begin
    test_awaddr_even();
    test_write_mux_even();
    test_write_even();

    test_write_even_pipeline();
    test_write_sequential_pipeline();

    #100;
    $finish;
  end

endmodule
