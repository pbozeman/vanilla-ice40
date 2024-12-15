`include "testing.sv"

`include "axi_stripe_interconnect.sv"
`include "axi_sram_controller.sv"
`include "sram_model.sv"

// verilator lint_off UNUSEDSIGNAL
//
// NOTE: use addrs below A000 for writing. Reads don't
// initialize memory and are letting the model fill return
// mocked data using the addr.
module axi_stripe_interconnect_tb;
  localparam NUM_M = 3;
  localparam NUM_S = 2;
  localparam AXI_ADDR_WIDTH = 20;
  localparam AXI_DATA_WIDTH = 16;
  localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8;

  logic                                 axi_clk;
  logic                                 axi_resetn;

  // Input AXI interfaces
  logic [NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_awaddr;
  logic [NUM_M-1:0]                     in_axi_awvalid;
  logic [NUM_M-1:0]                     in_axi_awready;
  logic [NUM_M-1:0][AXI_DATA_WIDTH-1:0] in_axi_wdata;
  logic [NUM_M-1:0][AXI_STRB_WIDTH-1:0] in_axi_wstrb;
  logic [NUM_M-1:0]                     in_axi_wvalid;
  logic [NUM_M-1:0]                     in_axi_wready;
  logic [NUM_M-1:0][               1:0] in_axi_bresp;
  logic [NUM_M-1:0]                     in_axi_bvalid;
  logic [NUM_M-1:0]                     in_axi_bready;
  logic [NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_araddr;
  logic [NUM_M-1:0]                     in_axi_arvalid;
  logic [NUM_M-1:0]                     in_axi_arready;
  logic [NUM_M-1:0][AXI_DATA_WIDTH-1:0] in_axi_rdata;
  logic [NUM_M-1:0][               1:0] in_axi_rresp;
  logic [NUM_M-1:0]                     in_axi_rvalid;
  logic [NUM_M-1:0]                     in_axi_rready;

  // Output AXI interface
  logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] out_axi_awaddr;
  logic [NUM_S-1:0]                     out_axi_awvalid;
  logic [NUM_S-1:0]                     out_axi_awready;
  logic [NUM_S-1:0][AXI_DATA_WIDTH-1:0] out_axi_wdata;
  logic [NUM_S-1:0][AXI_STRB_WIDTH-1:0] out_axi_wstrb;
  logic [NUM_S-1:0]                     out_axi_wvalid;
  logic [NUM_S-1:0]                     out_axi_wready;
  logic [NUM_S-1:0][               1:0] out_axi_bresp;
  logic [NUM_S-1:0]                     out_axi_bvalid;
  logic [NUM_S-1:0]                     out_axi_bready;
  logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] out_axi_araddr;
  logic [NUM_S-1:0]                     out_axi_arvalid;
  logic [NUM_S-1:0]                     out_axi_arready;
  logic [NUM_S-1:0][AXI_DATA_WIDTH-1:0] out_axi_rdata;
  logic [NUM_S-1:0][               1:0] out_axi_rresp;
  logic [NUM_S-1:0]                     out_axi_rvalid;
  logic [NUM_S-1:0]                     out_axi_rready;

  // SRAM
  logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [NUM_S-1:0][AXI_DATA_WIDTH-1:0] sram_io_data;
  logic [NUM_S-1:0]                     sram_io_we_n;
  logic [NUM_S-1:0]                     sram_io_oe_n;
  logic [NUM_S-1:0]                     sram_io_ce_n;

  logic [NUM_M-1:0]                     in_write_accepted;
  logic [NUM_M-1:0]                     in_read_accepted;

  axi_stripe_interconnect #(
      .NUM_M         (NUM_M),
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

  for (genvar i = 0; i < NUM_M; i++) begin : gen_m_signals
    assign in_write_accepted[i] = (in_axi_awvalid[i] && in_axi_awready[i] &&
                                   in_axi_wvalid[i] && in_axi_wready[i]);

    assign in_read_accepted[i] = (in_axi_arvalid[i] && in_axi_arready[i]);

    // auto clear manager valid flags
    always @(posedge axi_clk) begin
      if (in_axi_awvalid[i] && in_axi_awready[i]) begin
        in_axi_awvalid[i] <= 0;
      end

      if (in_axi_wvalid[i] && in_axi_wready[i]) begin
        in_axi_wvalid[i] <= 0;
      end

      if (in_axi_arvalid[i] && in_axi_arready[i]) begin
        in_axi_arvalid[i] <= 0;
      end
    end
  end

  `TEST_SETUP(axi_stripe_interconnect_tb);
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

  task test_awaddr_grant_even;
    begin
      test_line = `__LINE__;
      setup();

      `ASSERT_EQ(uut.wg_req[0], NUM_M);

      in_axi_awvalid[0] = 1'b1;
      in_axi_awaddr[0]  = 20'h1000;
      in_axi_wvalid[0]  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.wg_req[0], 0);
      `ASSERT_EQ(out_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h1000);

      setup();
      in_axi_awvalid[1] = 1'b1;
      in_axi_awaddr[1]  = 20'h2000;
      in_axi_wvalid[1]  = 1'b1;
      @(posedge axi_clk);
      #1;

      `ASSERT_EQ(uut.wg_req[0], 1);
      `ASSERT_EQ(out_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h2000);
    end
  endtask

  task test_write_mux_even;
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
      `ASSERT_EQ(uut.wg_req[0], 0);
      `ASSERT_EQ(out_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h1000);
      `ASSERT_EQ(out_axi_awvalid[0], 1'b1);
      `ASSERT_EQ(out_axi_wdata[0], 16'hDEAD);
      `ASSERT_EQ(out_axi_wvalid[0], 1'b1);
      `ASSERT_EQ(out_axi_wstrb[0], 2'b10);

      `ASSERT_EQ(out_axi_bready[0], 1'b0);
      `WAIT_FOR_SIGNAL(in_write_accepted[0]);

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(out_axi_bready[0], 1'b1);
    end
  endtask

  task test_write_even;
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

  task test_write_even_pipeline_multi;
    begin
      test_line = `__LINE__;
      setup();

      // Setup writes from 3 managers
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

      // First transaction grant and signals
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.wg_req[0], 0);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h1000);
      `ASSERT_EQ(out_axi_wdata[0], 16'hDEAD);

      `WAIT_FOR_SIGNAL(in_write_accepted[0]);

      // Second transaction got the grant
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.wg_req[0], 1);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h2000);
      `ASSERT_EQ(out_axi_wdata[0], 16'hBEEF);

      `WAIT_FOR_SIGNAL(in_write_accepted[1]);

      // Third
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(uut.wg_req[0], 2);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h3000);
      `ASSERT_EQ(out_axi_wdata[0], 16'hCAFE);

      `WAIT_FOR_SIGNAL(in_write_accepted[2]);
    end
  endtask

  task test_write_even_pipeline_multi_bvalid;
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

      `WAIT_FOR_SIGNAL(in_axi_bvalid[0]);
      `WAIT_FOR_SIGNAL(in_axi_bvalid[1]);
      `WAIT_FOR_SIGNAL(in_axi_bvalid[2]);
    end
  endtask

  task test_write_even_pipeline_single;
    begin
      test_line = `__LINE__;
      setup();

      // First write from in0 to even address
      in_axi_awaddr[0]  = 20'h1000;
      in_axi_awvalid[0] = 1'b1;
      in_axi_wdata[0]   = 16'hDEAD;
      in_axi_wstrb[0]   = 2'b11;
      in_axi_wvalid[0]  = 1'b1;
      in_axi_bready[0]  = 1'b1;

      @(posedge axi_clk);
      // Check first transaction grant and signals
      #1;
      `ASSERT_EQ(uut.wg_req[0], 0);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h1000);
      `ASSERT_EQ(out_axi_wdata[0], 16'hDEAD);

      // setup write from same source (in0)
      in_axi_awaddr[0]  = 20'h2000;
      in_axi_awvalid[0] = 1'b1;
      in_axi_wdata[0]   = 16'hBEEF;
      in_axi_wstrb[0]   = 2'b11;
      in_axi_wvalid[0]  = 1'b1;
      in_axi_bready[0]  = 1'b1;

      `WAIT_FOR_SIGNAL(in_write_accepted[0]);

      // Check second transaction grant and signals.
      #1;
      `ASSERT_EQ(uut.wg_req[0], 0);
      `ASSERT_EQ(out_axi_awaddr[0], 20'h2000);
      `ASSERT_EQ(out_axi_wdata[0], 16'hBEEF);

      // Wait for B channel to complete
      `WAIT_FOR_SIGNAL(in_axi_bvalid[0]);
    end
  endtask

  task test_read_even;
    begin
      test_line = `__LINE__;
      setup();

      in_axi_araddr[0]  = 20'hA000;
      in_axi_arvalid[0] = 1'b1;
      in_axi_rready[0]  = 1'b1;
      @(posedge axi_clk);

      #1;
      `ASSERT_EQ(in_axi_arvalid[0], 1'b1);
      `WAIT_FOR_SIGNAL(out_axi_rvalid[0]);
      `ASSERT_EQ(in_axi_rvalid[0], 1'b1);
      `ASSERT_EQ(in_axi_rdata[0], 16'hA000);
    end
  endtask

  task test_read_even_pipeline_multi;
    begin
      test_line = `__LINE__;
      setup();

      in_axi_araddr[0]  = 20'hA000;
      in_axi_arvalid[0] = 1'b1;
      in_axi_rready[0]  = 1'b1;

      in_axi_araddr[1]  = 20'hB000;
      in_axi_arvalid[1] = 1'b1;
      in_axi_rready[1]  = 1'b1;

      in_axi_araddr[2]  = 20'hC000;
      in_axi_arvalid[2] = 1'b1;
      in_axi_rready[2]  = 1'b1;

      // Wait for data phase completions
      `WAIT_FOR_SIGNAL(in_axi_rvalid[0]);
      `ASSERT_EQ(in_axi_rdata[0], 16'hA000);

      `WAIT_FOR_SIGNAL(in_axi_rvalid[1]);
      `ASSERT_EQ(in_axi_rdata[1], 16'hB000);

      `WAIT_FOR_SIGNAL(in_axi_rvalid[2]);
      `ASSERT_EQ(in_axi_rdata[2], 16'hC000);
    end
  endtask

  task test_read_even_pipeline_single;
    begin
      test_line = `__LINE__;
      setup();

      // First read from in0
      in_axi_araddr[0]  = 20'hA000;
      in_axi_arvalid[0] = 1'b1;
      in_axi_rready[0]  = 1'b1;

      // Wait for address phase to complete
      `WAIT_FOR_SIGNAL(in_read_accepted[0]);

      // Check first transaction grant and signals
      `ASSERT_EQ(uut.rg_req[0], 0);
      `ASSERT_EQ(out_axi_araddr[0], 20'hA000);

      // Second read from same source (in0)
      @(negedge axi_clk);
      in_axi_araddr[0]  = 20'hB000;
      in_axi_arvalid[0] = 1'b1;
      in_axi_rready[0]  = 1'b1;

      `WAIT_FOR_SIGNAL(in_axi_rvalid[0]);
      `ASSERT_EQ(in_axi_rdata[0], 16'hA000);

      @(negedge axi_clk);

      `WAIT_FOR_SIGNAL(in_axi_rvalid[0]);
      `ASSERT_EQ(in_axi_rdata[0], 16'hB000);
    end
  endtask

  task test_write_sequential_pipeline_multi_bvalid;
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

      in_axi_awaddr[1]  = 20'h2001;
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

      `WAIT_FOR_SIGNAL(in_axi_bvalid[0]);
      `ASSERT_EQ(in_axi_bvalid[1], 1);
      `WAIT_FOR_SIGNAL(in_axi_bvalid[2]);
    end
  endtask

  initial begin
    test_awaddr_grant_even();
    test_write_mux_even();

    test_write_even();
    test_write_even_pipeline_multi();
    test_write_even_pipeline_multi_bvalid();
    test_write_even_pipeline_single();

    test_read_even();
    test_read_even_pipeline_multi();
    test_read_even_pipeline_single();

    test_write_sequential_pipeline_multi_bvalid;

    // TODO: it would be great to parallel io tests to the subordinates and
    // other complex io patterns. Do this if bugs show up in as part of use
    // in the higher level modules, both for debugging and to catch furture
    // regressions.

    #100;
    $finish;
  end

endmodule
