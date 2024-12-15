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

  logic [AXI_ADDR_WIDTH-1:0]                     in_axi_awaddr;
  logic                                          in_axi_awvalid;
  logic                                          in_axi_awready;
  logic [AXI_DATA_WIDTH-1:0]                     in_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0]                     in_axi_wstrb;
  logic                                          in_axi_wvalid;
  logic                                          in_axi_wready;
  logic [               1:0]                     in_axi_bresp;
  logic                                          in_axi_bvalid;
  logic                                          in_axi_bready;
  logic [AXI_ADDR_WIDTH-1:0]                     in_axi_araddr;
  logic                                          in_axi_arvalid;
  logic                                          in_axi_arready;
  logic [AXI_DATA_WIDTH-1:0]                     in_axi_rdata;
  logic [               1:0]                     in_axi_rresp;
  logic                                          in_axi_rvalid;
  logic                                          in_axi_rready;

  // Output AXI interface
  logic [         NUM_S-1:0][AXI_ADDR_WIDTH-1:0] out_axi_awaddr;
  logic [         NUM_S-1:0]                     out_axi_awvalid;
  logic [         NUM_S-1:0]                     out_axi_awready;
  logic [         NUM_S-1:0][AXI_DATA_WIDTH-1:0] out_axi_wdata;
  logic [         NUM_S-1:0][AXI_STRB_WIDTH-1:0] out_axi_wstrb;
  logic [         NUM_S-1:0]                     out_axi_wvalid;
  logic [         NUM_S-1:0]                     out_axi_wready;
  logic [         NUM_S-1:0][               1:0] out_axi_bresp;
  logic [         NUM_S-1:0]                     out_axi_bvalid;
  logic [         NUM_S-1:0]                     out_axi_bready;
  logic [         NUM_S-1:0][AXI_ADDR_WIDTH-1:0] out_axi_araddr = '0;
  logic [         NUM_S-1:0]                     out_axi_arvalid = '0;
  logic [         NUM_S-1:0]                     out_axi_arready;
  logic [         NUM_S-1:0][AXI_DATA_WIDTH-1:0] out_axi_rdata;
  logic [         NUM_S-1:0][               1:0] out_axi_rresp;
  logic [         NUM_S-1:0]                     out_axi_rvalid;
  logic [         NUM_S-1:0]                     out_axi_rready = '0;

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
      .*
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
        .axi_awaddr  (out_axi_awaddr[i]),
        .axi_awvalid (out_axi_awvalid[i]),
        .axi_awready (out_axi_awready[i]),
        .axi_wdata   (out_axi_wdata[i]),
        .axi_wstrb   (out_axi_wstrb[i]),
        .axi_wvalid  (out_axi_wvalid[i]),
        .axi_wready  (out_axi_wready[i]),
        .axi_bresp   (out_axi_bresp[i]),
        .axi_bvalid  (out_axi_bvalid[i]),
        .axi_bready  (out_axi_bready[i]),
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

  // auto clear manager valid flags
  always @(posedge axi_clk) begin
    if (in_axi_awvalid && in_axi_awready) begin
      in_axi_awvalid <= 0;
    end

    if (in_axi_wvalid && in_axi_wready) begin
      in_axi_wvalid <= 0;
    end
  end

  assign in_write_accepted = (in_axi_awvalid && in_axi_awready &&
                              in_axi_wvalid && in_axi_wready);


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
      axi_resetn     = 0;

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

  task test_awaddr_even;
    begin
      test_line = `__LINE__;
      setup();

      `ASSERT_EQ(uut.req, '1);

      in_axi_awvalid = 1'b1;
      in_axi_awaddr  = 20'h1000;
      in_axi_wvalid  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.req, 0);
      `ASSERT_EQ(out_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h1000);

      setup();
      in_axi_awvalid = 1'b1;
      in_axi_awaddr  = 20'h2001;
      in_axi_wvalid  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.req, 1);
      `ASSERT_EQ(out_axi_awvalid[1], 1'b1);
      `ASSERT_EQ(out_axi_awaddr[1], 20'h2001);
    end
  endtask

  task test_write_mux_even;
    begin
      test_line = `__LINE__;
      setup();

      in_axi_awaddr  = 20'h1000;
      in_axi_awvalid = 1'b1;
      in_axi_wdata   = 16'hDEAD;
      in_axi_wstrb   = 2'b10;
      in_axi_wvalid  = 1'b1;
      in_axi_bready  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.req, 0);
      `ASSERT_EQ(out_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h1000);
      `ASSERT_EQ(out_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(out_axi_wdata[0], 16'hDEAD);
      `ASSERT_EQ(out_axi_wvalid[0], 1'b1);
      `ASSERT_EQ(out_axi_wstrb[0], 2'b10);

      `ASSERT_EQ(out_axi_bready[0], 1'b0);
      `WAIT_FOR_SIGNAL(in_write_accepted);

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(out_axi_bready[0], 1'b1);
    end
  endtask

  task test_write_even;
    begin
      test_line = `__LINE__;
      setup();

      in_axi_awaddr  = 20'h1000;
      in_axi_awvalid = 1'b1;
      in_axi_wdata   = 16'hDEAD;
      in_axi_wstrb   = 2'b10;
      in_axi_wvalid  = 1'b1;
      in_axi_bready  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(in_axi_awvalid, 1'b1);
      `ASSERT_EQ(in_axi_awready, 1'b1);
      `ASSERT_EQ(in_axi_wvalid, 1'b1);
      `ASSERT_EQ(in_axi_wready, 1'b1);

      `WAIT_FOR_SIGNAL(in_axi_bvalid);
    end
  endtask

  task test_write_even_pipeline;
    begin
      test_line = `__LINE__;
      setup();

      // First write to even
      in_axi_awaddr  = 20'h1000;
      in_axi_awvalid = 1'b1;
      in_axi_wdata   = 16'hDEAD;
      in_axi_wstrb   = 2'b11;
      in_axi_wvalid  = 1'b1;
      in_axi_bready  = 1'b1;

      @(posedge axi_clk);
      // Check first transaction signals
      #1;
      `ASSERT_EQ(uut.req, 0);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h1000);
      `ASSERT_EQ(out_axi_wdata[0], 16'hDEAD);

      // second write while first is in flight
      in_axi_awaddr  = 20'h2000;
      in_axi_awvalid = 1'b1;
      in_axi_wdata   = 16'hBEEF;
      in_axi_wstrb   = 2'b11;
      in_axi_wvalid  = 1'b1;
      in_axi_bready  = 1'b1;

      `WAIT_FOR_SIGNAL(in_write_accepted);

      // Check second transaction grant and signals.
      #1;
      `ASSERT_EQ(uut.req, 0);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h2000);
      `ASSERT_EQ(out_axi_wdata[0], 16'hBEEF);

      // Wait for B channel to complete
      `WAIT_FOR_SIGNAL(in_axi_bvalid);
    end
  endtask

  task test_write_sequential_pipeline;
    begin
      test_line = `__LINE__;
      setup();

      // First write from to even
      in_axi_awaddr  = 20'h1000;
      in_axi_awvalid = 1'b1;
      in_axi_wdata   = 16'hDEAD;
      in_axi_wstrb   = 2'b11;
      in_axi_wvalid  = 1'b1;
      in_axi_bready  = 1'b1;

      @(posedge axi_clk);
      // Check first transaction signals
      #1;
      `ASSERT_EQ(uut.req, 0);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h1000);
      `ASSERT_EQ(out_axi_wdata[0], 16'hDEAD);

      // then to odd
      in_axi_awaddr  = 20'h2001;
      in_axi_awvalid = 1'b1;
      in_axi_wdata   = 16'hBEEF;
      in_axi_wstrb   = 2'b11;
      in_axi_wvalid  = 1'b1;
      in_axi_bready  = 1'b1;

      `WAIT_FOR_SIGNAL(in_write_accepted);

      // Check second transaction grant and signals.
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.req, 1);
      `ASSERT_EQ(out_axi_awaddr[1], 20'h2001);
      `ASSERT_EQ(out_axi_wdata[1], 16'hBEEF);

      // Wait for B channel to complete
      `WAIT_FOR_SIGNAL(in_axi_bvalid);

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
