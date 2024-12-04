`include "testing.sv"

`include "axi_arbiter.sv"


// TODO: add more tests. Specifically, add pipeline request from the same and
// different managers. Test that the resp flows through. This started as
// a combo mux and arbiter, and implicitly had those sort of tests when hooked
// up to a full mocked sram, but now that the mux is stripped out, the lowest
// tests aren't there. On the other hand they will be covered as part of the
// full axi_stripe_interconnect tests. (Or if this is being read in the future,
// already are).

// verilator lint_off UNUSEDSIGNAL
module axi_arbiter_tb;
  localparam NUM_M = 3;
  localparam SEL_BITS = 1;
  localparam G_BITS = $clog2(NUM_M + 1);

  localparam AXI_ADDR_WIDTH = 20;

  logic                                    axi_clk;
  logic                                    axi_resetn;

  logic [SEL_BITS-1:0]                     a_sel;

  logic [  G_BITS-1:0]                     rg_req;
  logic [  G_BITS-1:0]                     wg_req;

  logic [  G_BITS-1:0]                     rg_resp;
  logic [  G_BITS-1:0]                     wg_resp;

  // Input AXI interfaces
  logic [   NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_awaddr;
  logic [   NUM_M-1:0]                     in_axi_awvalid;
  logic [   NUM_M-1:0]                     in_axi_awready;
  logic [   NUM_M-1:0]                     in_axi_wvalid;
  logic [   NUM_M-1:0]                     in_axi_wready;
  logic [   NUM_M-1:0]                     in_axi_bvalid;
  logic [   NUM_M-1:0]                     in_axi_bready;
  logic [   NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_araddr;
  logic [   NUM_M-1:0]                     in_axi_arvalid;
  logic [   NUM_M-1:0]                     in_axi_arready;
  logic [   NUM_M-1:0][               1:0] in_axi_rresp;
  logic [   NUM_M-1:0]                     in_axi_rvalid;
  logic [   NUM_M-1:0]                     in_axi_rready;

  logic [         8:0]                     test_line;

  // UUT instantiation
  axi_arbiter #(
      .NUM_M         (NUM_M),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
  ) uut (
      .*
  );

  `TEST_SETUP(axi_arbiter_tb);

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
      a_sel          = 0;

      // Reset all input signals
      in_axi_awaddr  = '0;
      in_axi_awvalid = '0;
      in_axi_wvalid  = '0;
      in_axi_bready  = '0;
      in_axi_araddr  = '0;
      in_axi_arvalid = '0;
      in_axi_rready  = '0;

      in_axi_awready = '0;
      in_axi_wready  = '0;
      in_axi_bvalid  = '0;
      in_axi_arready = '0;
      in_axi_rvalid  = '0;

      @(posedge axi_clk);
      axi_resetn = 1;
      @(posedge axi_clk);
    end
  endtask

  task test_awaddr_grant;
    begin
      test_line = `__LINE__;
      setup();

      `ASSERT_EQ(wg_req, NUM_M);

      in_axi_awvalid[0] = 1'b1;
      in_axi_awaddr[0]  = 20'h1000;
      in_axi_wvalid[0]  = 1'b1;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(wg_req, 0);

      setup();
      in_axi_awvalid[1] = 1'b1;
      in_axi_awaddr[1]  = 20'h2000;
      in_axi_wvalid[1]  = 1'b1;
      @(posedge axi_clk);
      #1;

      `ASSERT_EQ(wg_req, 1);
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
      `ASSERT_EQ(wg_req, 0);

      setup();
      in_axi_awaddr[1]  = 20'h2000;
      in_axi_awvalid[1] = 1'b1;
      in_axi_awaddr[2]  = 20'h3000;
      in_axi_awvalid[2] = 1'b1;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(wg_req, 1);
    end
  endtask

  task test_araddr_grant;
    begin
      test_line = `__LINE__;
      setup();

      `ASSERT_EQ(rg_req, NUM_M);

      in_axi_arvalid[0] = 1'b1;
      in_axi_araddr[0]  = 20'hA000;

      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(rg_req, 0);

      setup();
      in_axi_arvalid[1] = 1'b1;
      in_axi_araddr[1]  = 20'hA000;
      @(posedge axi_clk);
      #1;

      `ASSERT_EQ(rg_req, 1);
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
      `ASSERT_EQ(rg_req, 0);

      setup();
      in_axi_araddr[1]  = 20'hB000;
      in_axi_arvalid[1] = 1'b1;
      in_axi_araddr[2]  = 20'hC000;
      in_axi_arvalid[2] = 1'b1;
      @(posedge axi_clk);
      #1;
      `ASSERT_EQ(rg_req, 1);
    end
  endtask

  // Test sequence
  initial begin
    test_awaddr_grant();
    test_awaddr_grant_pri();

    test_araddr_grant();
    test_araddr_grant_pri();

    #100;

    $finish;
  end

endmodule

// verilator lint_on UNUSEDSIGNAL
