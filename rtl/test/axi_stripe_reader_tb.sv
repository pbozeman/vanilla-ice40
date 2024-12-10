`include "testing.sv"

`include "axi_sram_controller.sv"
`include "axi_stripe_reader.sv"
`include "sram_model.sv"

// Per the axi spec, arlen is a 0 based count, so 0 is 1 transfer, 1 is 2,
// etc.

// verilator lint_off UNUSEDSIGNAL
module axi_stripe_reader_tb;
  localparam NUM_S = 2;
  localparam AXI_ADDR_WIDTH = 20;
  localparam AXI_DATA_WIDTH = 16;
  localparam AXI_ARLENW_WIDTH = 8;

  logic                                            axi_clk;
  logic                                            axi_resetn = 0;

  // Manager interface signals
  logic [  AXI_ADDR_WIDTH-1:0]                     in_axi_araddr;
  logic [AXI_ARLENW_WIDTH-1:0]                     in_axi_arlenw;
  logic                                            in_axi_arvalid;
  logic                                            in_axi_arready;
  logic [  AXI_DATA_WIDTH-1:0]                     in_axi_rdata;
  logic [                 1:0]                     in_axi_rresp;
  logic                                            in_axi_rvalid;
  logic                                            in_axi_rlast;
  logic                                            in_axi_rready;

  // Subordinate interface signals
  logic [           NUM_S-1:0][AXI_ADDR_WIDTH-1:0] out_axi_araddr;
  logic [           NUM_S-1:0]                     out_axi_arvalid;
  logic [           NUM_S-1:0]                     out_axi_arready;
  logic [           NUM_S-1:0][AXI_DATA_WIDTH-1:0] out_axi_rdata;
  logic [           NUM_S-1:0][               1:0] out_axi_rresp;
  logic [           NUM_S-1:0]                     out_axi_rvalid;
  logic [           NUM_S-1:0]                     out_axi_rready;

  // SRAM
  logic [           NUM_S-1:0][AXI_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [           NUM_S-1:0][AXI_DATA_WIDTH-1:0] sram_io_data;
  logic [           NUM_S-1:0]                     sram_io_we_n;
  logic [           NUM_S-1:0]                     sram_io_oe_n;
  logic [           NUM_S-1:0]                     sram_io_ce_n;

  for (genvar i = 0; i < NUM_S; i++) begin : gen_s_modules
    sram_model #(
        .ADDR_BITS                (AXI_ADDR_WIDTH),
        .DATA_BITS                (AXI_DATA_WIDTH),
        .UNINITIALIZED_READS_FATAL(0)
    ) sram_model_i (
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
        .axi_araddr  (out_axi_araddr[i]),
        .axi_arvalid (out_axi_arvalid[i]),
        .axi_arready (out_axi_arready[i]),
        .axi_rdata   (out_axi_rdata[i]),
        .axi_rresp   (out_axi_rresp[i]),
        .axi_rvalid  (out_axi_rvalid[i]),
        .axi_rready  (out_axi_rready[i]),
        .sram_io_addr(sram_io_addr[i]),
        .sram_io_data(sram_io_data[i]),
        .sram_io_we_n(sram_io_we_n[i]),
        .sram_io_oe_n(sram_io_oe_n[i]),
        .sram_io_ce_n(sram_io_ce_n[i])
    );
  end

  axi_stripe_reader #(
      .NUM_S           (NUM_S),
      .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH  (AXI_DATA_WIDTH),
      .AXI_ARLENW_WIDTH(AXI_ARLENW_WIDTH)
  ) uut (
      .*
  );

  `TEST_SETUP(axi_stripe_reader_tb)

  // Clock generation
  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  logic [8:0] test_line;

  // Common test setup
  task setup();
    begin
      @(posedge axi_clk);
      axi_resetn     = 0;
      in_axi_araddr  = 0;
      in_axi_arlenw  = 0;
      in_axi_arvalid = 0;
      in_axi_rready  = 0;

      @(posedge axi_clk);
      axi_resetn = 1;
      @(posedge axi_clk);
    end
  endtask

  // Test single word read from each subordinate
  task test_stripe_1;
    begin
      test_line = `__LINE__;
      setup();

      // Read one word
      in_axi_araddr  = 20'h1000;
      in_axi_arlenw  = 1;
      in_axi_arvalid = 1;
      in_axi_rready  = 1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rdata, 16'h1000);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'h1001);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b0);

      `WAIT_FOR_SIGNAL(in_axi_arready);
    end
  endtask

  // Test multi-word read with striping
  task test_stripe_2;
    begin
      test_line = `__LINE__;
      setup();

      // Read two stripes
      in_axi_araddr  = 20'hA000;
      in_axi_arlenw  = 3;
      in_axi_arvalid = 1;
      in_axi_rready  = 1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rdata, 16'hA000);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hA001);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hA002);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hA003);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b0);

      `WAIT_FOR_SIGNAL(in_axi_arready);
    end
  endtask

  // Test multi-word read with striping and restart
  task test_stripe_restart;
    begin
      test_line = `__LINE__;
      setup();

      // Read four words
      in_axi_araddr  = 20'hA000;
      in_axi_arlenw  = 3;
      in_axi_arvalid = 1;
      in_axi_rready  = 1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rdata, 16'hA000);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hA001);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hA002);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hA003);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b0);

      `WAIT_FOR_SIGNAL(in_axi_arready);
      #1;

      in_axi_araddr  = 20'hB000;
      in_axi_arlenw  = 3;
      in_axi_arvalid = 1;
      in_axi_rready  = 1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid);
      `ASSERT_EQ(in_axi_rdata, 16'hB000);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hB001);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hB002);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b1);
      `ASSERT_EQ(in_axi_rdata, 16'hB003);

      @(posedge axi_clk);
      `ASSERT_EQ(in_axi_rvalid, 1'b0);
      `WAIT_FOR_SIGNAL(in_axi_arready);
    end
  endtask

  // Test sequence
  initial begin
    test_stripe_1();
    test_stripe_2();
    test_stripe_restart();

    #100;
    $finish;
  end

endmodule
// verilator lint_on UNUSEDSIGNAL
