`include "testing.sv"

`include "axi_arbiter.sv"
`include "axi_sram_controller.sv"
`include "sram_model.sv"

// verilator lint_off UNUSEDSIGNAL
//
// NOTE: use addrs below A000 for writing. Reads don't
// initialize memory and are letting the model fill return
// mocked data using the addr.
module axi_arbiter_tb;
  localparam NUM_M = 3;
  localparam SEL_BITS = 1;

  localparam AXI_ADDR_WIDTH = 20;
  localparam AXI_DATA_WIDTH = 16;
  localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8;

  logic                                          axi_clk;
  logic                                          axi_resetn;

  logic [      SEL_BITS-1:0]                     a_sel;

  // Input AXI interfaces
  logic [         NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_awaddr;
  logic [         NUM_M-1:0]                     in_axi_awvalid;
  logic [         NUM_M-1:0]                     in_axi_awready;
  logic [         NUM_M-1:0][AXI_DATA_WIDTH-1:0] in_axi_wdata;
  logic [         NUM_M-1:0][AXI_STRB_WIDTH-1:0] in_axi_wstrb;
  logic [         NUM_M-1:0]                     in_axi_wvalid;
  logic [         NUM_M-1:0]                     in_axi_wready;
  logic [         NUM_M-1:0][               1:0] in_axi_bresp;
  logic [         NUM_M-1:0]                     in_axi_bvalid;
  logic [         NUM_M-1:0]                     in_axi_bready;
  logic [         NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_araddr;
  logic [         NUM_M-1:0]                     in_axi_arvalid;
  logic [         NUM_M-1:0]                     in_axi_arready;
  logic [         NUM_M-1:0][AXI_DATA_WIDTH-1:0] in_axi_rdata;
  logic [         NUM_M-1:0][               1:0] in_axi_rresp;
  logic [         NUM_M-1:0]                     in_axi_rvalid;
  logic [         NUM_M-1:0]                     in_axi_rready;

  // Output AXI interface
  logic [AXI_ADDR_WIDTH-1:0]                     out_axi_awaddr;
  logic                                          out_axi_awvalid;
  logic                                          out_axi_awready;
  logic [AXI_DATA_WIDTH-1:0]                     out_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0]                     out_axi_wstrb;
  logic                                          out_axi_wvalid;
  logic                                          out_axi_wready;
  logic [               1:0]                     out_axi_bresp;
  logic                                          out_axi_bvalid;
  logic                                          out_axi_bready;
  logic [AXI_ADDR_WIDTH-1:0]                     out_axi_araddr;
  logic                                          out_axi_arvalid;
  logic                                          out_axi_arready;
  logic [AXI_DATA_WIDTH-1:0]                     out_axi_rdata;
  logic [               1:0]                     out_axi_rresp;
  logic                                          out_axi_rvalid;
  logic                                          out_axi_rready;

  logic [               8:0]                     test_line;

  // SRAM
  logic [AXI_ADDR_WIDTH-1:0]                     sram_io_addr;
  wire  [AXI_DATA_WIDTH-1:0]                     sram_io_data;
  logic                                          sram_io_we_n;
  logic                                          sram_io_oe_n;
  logic                                          sram_io_ce_n;

  sram_model #(
      .ADDR_BITS                (AXI_ADDR_WIDTH),
      .DATA_BITS                (AXI_DATA_WIDTH),
      .UNINITIALIZED_READS_FATAL(0)
  ) sram_model_i (
      .we_n   (sram_io_we_n),
      .oe_n   (sram_io_oe_n),
      .ce_n   (sram_io_ce_n),
      .addr   (sram_io_addr),
      .data_io(sram_io_data)
  );

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) axi_sram_ctrl_i (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .axi_awaddr  (out_axi_awaddr),
      .axi_awvalid (out_axi_awvalid),
      .axi_awready (out_axi_awready),
      .axi_wdata   (out_axi_wdata),
      .axi_wstrb   (out_axi_wstrb),
      .axi_wvalid  (out_axi_wvalid),
      .axi_wready  (out_axi_wready),
      .axi_bresp   (out_axi_bresp),
      .axi_bvalid  (out_axi_bvalid),
      .axi_bready  (out_axi_bready),
      .axi_araddr  (out_axi_araddr),
      .axi_arvalid (out_axi_arvalid),
      .axi_arready (out_axi_arready),
      .axi_rdata   (out_axi_rdata),
      .axi_rresp   (out_axi_rresp),
      .axi_rvalid  (out_axi_rvalid),
      .axi_rready  (out_axi_rready),
      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  // UUT instantiation
  axi_arbiter #(
      .NUM_M         (NUM_M),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) uut (
      .*
  );


  `TEST_SETUP(axi_arbiter_tb);

  // Clock generation
  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  // auto clear valid flags
  integer i;
  always @(posedge axi_clk) begin
    for (i = 0; i < NUM_M; i++) begin : gen_clear
      if (in_axi_awvalid[i] && in_axi_awready[i]) begin
        in_axi_awvalid[i] <= 0;
      end

      if (in_axi_wvalid[i] && in_axi_wready[i]) begin
        in_axi_wvalid[i] <= 0;
      end
    end

    if (in_axi_arvalid[i] && in_axi_arready[i]) begin
      in_axi_arvalid[i] <= 0;
    end
  end

  // Common test setup
  task setup();
    begin
      @(posedge axi_clk);
      axi_resetn     = 0;
      a_sel          = 0;

      // Reset all input signals
      in_axi_awaddr  = '0;
      in_axi_awvalid = '0;
      in_axi_wdata   = '0;
      in_axi_wstrb   = '0;
      in_axi_wvalid  = '0;
      in_axi_bready  = '0;
      in_axi_araddr  = '0;
      in_axi_arvalid = '0;
      in_axi_rready  = '0;

      @(posedge axi_clk);
      axi_resetn = 1;
      @(posedge axi_clk);
    end
  endtask

  task test_awaddr_grant;
    begin
      test_line = `__LINE__;
      setup();

      `ASSERT_EQ(uut.wg_req, NUM_M);

      in_axi_awvalid[0] = 1'b1;
      in_axi_awaddr[0]  = 20'h1000;
      in_axi_wvalid[0]  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.wg_req, 0);
      `ASSERT_EQ(out_axi_awvalid, 1'b1);
      `ASSERT_EQ(out_axi_awaddr, 20'h1000);

      setup();
      in_axi_awvalid[1] = 1'b1;
      in_axi_awaddr[1]  = 20'h2000;
      in_axi_wvalid[1]  = 1'b1;
      @(posedge axi_clk);
      #1;

      `ASSERT_EQ(uut.wg_req, 1);
      `ASSERT_EQ(out_axi_awvalid, 1'b1);
      `ASSERT_EQ(out_axi_awaddr, 20'h2000);
    end
  endtask

  task test_awaddr_grant_pri;
    begin
      test_line = `__LINE__;
      setup();

      in_axi_awaddr[0]  = 20'h1000;
      in_axi_awvalid[0] = 1'b1;
      in_axi_awaddr[1]  = 20'h2000;
      in_axi_awvalid[1] = 1'b1;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.wg_req, 0);
      `ASSERT_EQ(out_axi_awvalid, 1'b1);
      `ASSERT_EQ(out_axi_awaddr, 20'h1000);

      setup();
      in_axi_awaddr[1]  = 20'h2000;
      in_axi_awvalid[1] = 1'b1;
      in_axi_awaddr[2]  = 20'h3000;
      in_axi_awvalid[2] = 1'b1;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.wg_req, 1);
      `ASSERT_EQ(out_axi_awvalid, 1'b1);
      `ASSERT_EQ(out_axi_awaddr, 20'h2000);
    end
  endtask

  task test_araddr_grant;
    begin
      test_line = `__LINE__;
      setup();

      `ASSERT_EQ(uut.rg_req, NUM_M);

      in_axi_arvalid[0] = 1'b1;
      in_axi_araddr[0]  = 20'hA000;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.rg_req, 0);
      `ASSERT_EQ(out_axi_arvalid, 1'b1);
      `ASSERT_EQ(out_axi_araddr, 20'hA000);

      setup();
      in_axi_arvalid[1] = 1'b1;
      in_axi_araddr[1]  = 20'hA000;
      @(posedge axi_clk);
      #1;

      `ASSERT_EQ(uut.rg_req, 1);
      `ASSERT_EQ(out_axi_arvalid, 1'b1);
      `ASSERT_EQ(out_axi_araddr, 20'hA000);
    end
  endtask

  task test_araddr_grant_pri;
    begin
      test_line = `__LINE__;
      setup();

      in_axi_araddr[0]  = 20'hA000;
      in_axi_arvalid[0] = 1'b1;
      in_axi_araddr[1]  = 20'hB000;
      in_axi_arvalid[1] = 1'b1;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.rg_req, 0);
      `ASSERT_EQ(out_axi_arvalid, 1'b1);
      `ASSERT_EQ(out_axi_araddr, 20'hA000);

      setup();
      in_axi_araddr[1]  = 20'hB000;
      in_axi_arvalid[1] = 1'b1;
      in_axi_araddr[2]  = 20'hC000;
      in_axi_arvalid[2] = 1'b1;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.rg_req, 1);
      `ASSERT_EQ(out_axi_arvalid, 1'b1);
      `ASSERT_EQ(out_axi_araddr, 20'hB000);
    end
  endtask

  task test_write;
    begin
      test_line = `__LINE__;
      setup();

      in_axi_awaddr[0]  = 20'h1000;
      in_axi_awvalid[0] = 1'b1;
      in_axi_wdata[0]   = 16'hDEAD;
      in_axi_wstrb[0]   = 2'b10;
      in_axi_wvalid[0]  = 1'b1;
      in_axi_bready[0]  = 1'b1;
      @(posedge axi_clk);

      #1;
      `ASSERT_EQ(in_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(in_axi_awready[0], 1'b1);
      `ASSERT_EQ(in_axi_wvalid[0], 1'b1);
      `ASSERT_EQ(in_axi_wready[0], 1'b1);

      `WAIT_FOR_SIGNAL(in_axi_bvalid[0]);
    end
  endtask

  task test_read;
    begin
      test_line = `__LINE__;
      setup();

      in_axi_araddr[0]  = 20'hA000;
      in_axi_arvalid[0] = 1'b1;
      in_axi_rready[0]  = 1'b1;
      @(posedge axi_clk);

      #1;
      `ASSERT_EQ(in_axi_arvalid[0], 1'b1);
      `WAIT_FOR_SIGNAL(out_axi_rvalid);
      `ASSERT_EQ(in_axi_rvalid[0], 1'b1);
      `ASSERT_EQ(in_axi_rdata[0], 16'hA000);
    end
  endtask

  task test_write_pipeline;
    begin
      test_line = `__LINE__;
      setup();

      // queue them all up and then wait for their bvalids
      in_axi_awaddr[0]  = 20'h1000;
      in_axi_awvalid[0] = 1'b1;
      in_axi_wdata[0]   = 16'hDEAD;
      in_axi_wstrb[0]   = 2'b11;
      in_axi_wvalid[0]  = 1'b1;
      in_axi_bready[0]  = 1'b1;

      `WAIT_FOR_SIGNAL(in_axi_awready[0]);

      // the delay is needed because awaddr, etc is being auto cleared at the
      // top of the clock
      #0;
      in_axi_awaddr[0]  = 20'h2000;
      in_axi_awvalid[0] = 1'b1;
      in_axi_wdata[0]   = 16'hBEEF;
      in_axi_wstrb[0]   = 2'b11;
      in_axi_wvalid[0]  = 1'b1;
      in_axi_bready[0]  = 1'b1;

      `WAIT_FOR_SIGNAL(in_axi_awready[0]);

      #0;
      in_axi_awaddr[0]  = 20'h3000;
      in_axi_awvalid[0] = 1'b1;
      in_axi_wdata[0]   = 16'hCAFE;
      in_axi_wstrb[0]   = 2'b11;
      in_axi_wvalid[0]  = 1'b1;
      in_axi_bready[0]  = 1'b1;

      `WAIT_FOR_SIGNAL(in_axi_awready[0]);
    end
  endtask

  task test_multi_source_write_pipeline;
    begin
      test_line = `__LINE__;
      setup();

      // queue them all up and then wait for their bvalids
      in_axi_awaddr[0]  = 20'h1000;
      in_axi_awvalid[0] = 1'b1;
      in_axi_wdata[0]   = 16'hDEAD;
      in_axi_wstrb[0]   = 2'b11;
      in_axi_wvalid[0]  = 1'b1;
      in_axi_bready[0]  = 1'b1;

      in_axi_awaddr[1]  = 20'h2000;
      in_axi_awvalid[1] = 1'b1;
      in_axi_wdata[1]   = 16'hBEEF;
      in_axi_wstrb[1]   = 2'b11;
      in_axi_wvalid[1]  = 1'b1;
      in_axi_bready[1]  = 1'b1;

      in_axi_awaddr[2]  = 20'h3000;
      in_axi_awvalid[2] = 1'b1;
      in_axi_wdata[2]   = 16'hCAFE;
      in_axi_wstrb[2]   = 2'b11;
      in_axi_wvalid[2]  = 1'b1;
      in_axi_bready[2]  = 1'b1;

      @(negedge axi_clk);
      `WAIT_FOR_SIGNAL(in_axi_bvalid[0]);
      `WAIT_FOR_SIGNAL(in_axi_bvalid[1]);
      `WAIT_FOR_SIGNAL(in_axi_bvalid[2]);
    end
  endtask

  // Test sequence
  initial begin
    test_awaddr_grant();
    test_awaddr_grant_pri();

    test_araddr_grant();
    test_araddr_grant_pri();

    test_write();
    test_read();

    test_write_pipeline();
    test_multi_source_write_pipeline();
    #100;

    $finish;
  end

endmodule

// verilator lint_on UNUSEDSIGNAL
