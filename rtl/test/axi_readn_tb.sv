`include "testing.sv"
`include "axi_readn.sv"
`include "axi_sram_controller.sv"
`include "sram_model.sv"

// verilator lint_off UNUSEDSIGNAL
module axi_readn_tb;

  parameter STRIDE = 2;
  parameter AXI_ADDR_WIDTH = 20;
  parameter AXI_DATA_WIDTH = 16;
  parameter AXI_ARLENW_WIDTH = 8;

  logic                        axi_clk;
  logic                        axi_resetn;

  // Input interface signals
  logic [  AXI_ADDR_WIDTH-1:0] in_axi_araddr;
  logic [AXI_ARLENW_WIDTH-1:0] in_axi_arlenw;
  logic                        in_axi_arvalid;
  logic                        in_axi_arready;
  logic [  AXI_DATA_WIDTH-1:0] in_axi_rdata;
  logic [                 1:0] in_axi_rresp;
  logic                        in_axi_rvalid;
  logic                        in_axi_rlast;
  logic                        in_axi_rready;

  // Output interface signals
  logic [  AXI_ADDR_WIDTH-1:0] out_axi_araddr;
  logic                        out_axi_arvalid;
  logic                        out_axi_arready;
  logic [  AXI_DATA_WIDTH-1:0] out_axi_rdata;
  logic [                 1:0] out_axi_rresp;
  logic                        out_axi_rvalid;
  logic                        out_axi_rready;

  // Test line number tracking
  logic [                 8:0] test_line;

  // SRAM
  logic [  AXI_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [  AXI_DATA_WIDTH-1:0] sram_io_data;
  logic                        sram_io_we_n;
  logic                        sram_io_oe_n;
  logic                        sram_io_ce_n;

  sram_model #(
      .ADDR_BITS                (AXI_ADDR_WIDTH),
      .DATA_BITS                (AXI_DATA_WIDTH),
      .UNINITIALIZED_READS_FATAL(0)
  ) sram (
      .we_n   (sram_io_we_n),
      .oe_n   (sram_io_oe_n),
      .ce_n   (sram_io_ce_n),
      .addr   (sram_io_addr),
      .data_io(sram_io_data)
  );

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .axi_awaddr  (),
      .axi_awvalid (1'b0),
      .axi_awready (),
      .axi_wdata   (),
      .axi_wstrb   (),
      .axi_wvalid  (1'b0),
      .axi_wready  (),
      .axi_bresp   (),
      .axi_bvalid  (),
      .axi_bready  (1'b0),
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

  axi_readn #(
      .STRIDE          (STRIDE),
      .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH  (AXI_DATA_WIDTH),
      .AXI_ARLENW_WIDTH(AXI_ARLENW_WIDTH)
  ) uut (
      .*
  );

  `TEST_SETUP(axi_readn_tb)

  // Clock generation
  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  always @(posedge axi_clk) begin
    if (in_axi_arvalid && in_axi_arready) begin
      in_axi_arvalid <= 1'b0;
    end
  end

  // Common setup task
  task setup();
    begin
      @(posedge axi_clk);
      axi_resetn     = 0;
      axi_resetn     = 0;
      in_axi_araddr  = 0;
      in_axi_arlenw  = 0;
      in_axi_arvalid = 0;
      in_axi_rready  = 0;
      @(posedge axi_clk);

      @(posedge axi_clk);
      axi_resetn = 1;
      @(posedge axi_clk);
    end
  endtask

  task test_single_read;
    begin
      test_line = `__LINE__;
      setup();

      // Start read request
      in_axi_araddr  = 20'hA000;
      in_axi_arlenw  = 0;
      in_axi_arvalid = 1;
      in_axi_rready  = 1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rdata, 16'hA000);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b0);

      `WAIT_FOR_SIGNAL(in_axi_arready);
    end
  endtask

  task test_burst_read_2;
    begin
      test_line = `__LINE__;
      setup();

      // Start burst read request
      in_axi_araddr  = 20'hB000;
      in_axi_arlenw  = 8'h1;
      in_axi_arvalid = 1;
      in_axi_rready  = 1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rdata, 16'hB000);

      // stride is 2
      @(posedge axi_clk);
      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hB002);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b0);
      `WAIT_FOR_SIGNAL(in_axi_arready);
    end
  endtask

  task test_burst_read_3;
    begin
      test_line = `__LINE__;
      setup();

      // Start burst read request
      in_axi_araddr  = 20'hB000;
      in_axi_arlenw  = 8'h2;
      in_axi_arvalid = 1;
      in_axi_rready  = 1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rdata, 16'hB000);

      // stride is 2
      @(posedge axi_clk);
      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hB002);

      @(posedge axi_clk);
      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hB004);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b0);
      `WAIT_FOR_SIGNAL(in_axi_arready);
    end
  endtask

  task test_burst_read_delay;
    begin
      test_line = `__LINE__;
      setup();

      // Start burst read request
      in_axi_araddr  = 20'hB000;
      in_axi_arlenw  = 8'h3;
      in_axi_arvalid = 1;
      in_axi_rready  = 1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rdata, 16'hB000);

      in_axi_rready = 0;
      @(posedge axi_clk);
      @(posedge axi_clk);
      @(posedge axi_clk);
      @(posedge axi_clk);
      in_axi_rready = 1;

      // stride is 2
      @(posedge axi_clk);
      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hB002);

      @(posedge axi_clk);
      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hB004);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b0);
      `WAIT_FOR_SIGNAL(in_axi_arready);
    end
  endtask

  task test_burst_read_2_again;
    begin
      test_line = `__LINE__;
      setup();

      // Start burst read request
      in_axi_araddr  = 20'hB000;
      in_axi_arlenw  = 8'h1;
      in_axi_arvalid = 1;
      in_axi_rready  = 1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rdata, 16'hB000);

      // stride is 2
      @(posedge axi_clk);
      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hB002);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b0);

      `WAIT_FOR_SIGNAL(in_axi_arready);

      //
      // Second request
      //
      in_axi_araddr  = 20'hC000;
      in_axi_arlenw  = 8'h1;
      in_axi_arvalid = 1;
      in_axi_rready  = 1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rdata, 16'hC000);

      // stride is 2
      @(posedge axi_clk);
      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hC002);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b0);
      `WAIT_FOR_SIGNAL(in_axi_arready);
    end
  endtask


  // Test sequence
  initial begin
    // test_single_read();
    // test_burst_read_2();
    // test_burst_read_3();
    // test_burst_read_delay();

    test_burst_read_2_again();
    #100;

    $finish;
  end

endmodule
// verilator lint_on UNUSEDSIGNAL
