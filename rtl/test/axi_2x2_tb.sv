`include "testing.sv"

`include "axi_2x2.sv"

// TODO: test all of the signals
// verilator lint_off UNUSEDSIGNAL

module axi_2x2_tb;

  parameter AXI_ADDR_WIDTH = 20;
  parameter AXI_DATA_WIDTH = 16;

  logic                              axi_clk;
  logic                              axi_rst_n;
  logic                              switch_sel;
  logic                              sel;

  logic [        AXI_ADDR_WIDTH-1:0] in0_axi_awaddr;
  logic                              in0_axi_awvalid;
  logic                              in0_axi_awready;
  logic [        AXI_DATA_WIDTH-1:0] in0_axi_wdata;
  logic [((AXI_DATA_WIDTH+7)/8)-1:0] in0_axi_wstrb;
  logic                              in0_axi_wvalid;
  logic                              in0_axi_wready;
  logic [                       1:0] in0_axi_bresp;
  logic                              in0_axi_bvalid;
  logic                              in0_axi_bready;
  logic [        AXI_ADDR_WIDTH-1:0] in0_axi_araddr;
  logic                              in0_axi_arvalid;
  logic                              in0_axi_arready;
  logic [        AXI_DATA_WIDTH-1:0] in0_axi_rdata;
  logic [                       1:0] in0_axi_rresp;
  logic                              in0_axi_rvalid;
  logic                              in0_axi_rready;

  logic [        AXI_ADDR_WIDTH-1:0] in1_axi_awaddr;
  logic                              in1_axi_awvalid;
  logic                              in1_axi_awready;
  logic [        AXI_DATA_WIDTH-1:0] in1_axi_wdata;
  logic [((AXI_DATA_WIDTH+7)/8)-1:0] in1_axi_wstrb;
  logic                              in1_axi_wvalid;
  logic                              in1_axi_wready;
  logic [                       1:0] in1_axi_bresp;
  logic                              in1_axi_bvalid;
  logic                              in1_axi_bready;
  logic [        AXI_ADDR_WIDTH-1:0] in1_axi_araddr;
  logic                              in1_axi_arvalid;
  logic                              in1_axi_arready;
  logic [        AXI_DATA_WIDTH-1:0] in1_axi_rdata;
  logic [                       1:0] in1_axi_rresp;
  logic                              in1_axi_rvalid;
  logic                              in1_axi_rready;

  logic [        AXI_ADDR_WIDTH-1:0] out0_axi_awaddr;
  logic                              out0_axi_awvalid;
  logic                              out0_axi_awready;
  logic [        AXI_DATA_WIDTH-1:0] out0_axi_wdata;
  logic [((AXI_DATA_WIDTH+7)/8)-1:0] out0_axi_wstrb;
  logic                              out0_axi_wvalid;
  logic                              out0_axi_wready;
  logic [                       1:0] out0_axi_bresp;
  logic                              out0_axi_bvalid;
  logic                              out0_axi_bready;
  logic [        AXI_ADDR_WIDTH-1:0] out0_axi_araddr;
  logic                              out0_axi_arvalid;
  logic                              out0_axi_arready;
  logic [        AXI_DATA_WIDTH-1:0] out0_axi_rdata;
  logic [                       1:0] out0_axi_rresp;
  logic                              out0_axi_rvalid;
  logic                              out0_axi_rready;

  logic [        AXI_ADDR_WIDTH-1:0] out1_axi_awaddr;
  logic                              out1_axi_awvalid;
  logic                              out1_axi_awready;
  logic [        AXI_DATA_WIDTH-1:0] out1_axi_wdata;
  logic [((AXI_DATA_WIDTH+7)/8)-1:0] out1_axi_wstrb;
  logic                              out1_axi_wvalid;
  logic                              out1_axi_wready;
  logic [                       1:0] out1_axi_bresp;
  logic                              out1_axi_bvalid;
  logic                              out1_axi_bready;
  logic [        AXI_ADDR_WIDTH-1:0] out1_axi_araddr;
  logic                              out1_axi_arvalid;
  logic                              out1_axi_arready;
  logic [        AXI_DATA_WIDTH-1:0] out1_axi_rdata;
  logic [                       1:0] out1_axi_rresp;
  logic                              out1_axi_rvalid;
  logic                              out1_axi_rready;

  axi_2x2 #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) uut (
      .*
  );

  `TEST_SETUP(axi_2x2_tb);

  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  initial begin
    axi_rst_n        = 0;
    switch_sel       = 0;
    in0_axi_awaddr   = 0;
    in0_axi_awvalid  = 0;
    in0_axi_wdata    = 0;
    in0_axi_wstrb    = 0;
    in0_axi_wvalid   = 0;
    in0_axi_bready   = 0;
    in0_axi_araddr   = 0;
    in0_axi_arvalid  = 0;
    in0_axi_rready   = 0;
    in1_axi_awaddr   = 0;
    in1_axi_awvalid  = 0;
    in1_axi_wdata    = 0;
    in1_axi_wstrb    = 0;
    in1_axi_wvalid   = 0;
    in1_axi_bready   = 0;
    in1_axi_araddr   = 0;
    in1_axi_arvalid  = 0;
    in1_axi_rready   = 0;
    out0_axi_awready = 0;
    out0_axi_wready  = 0;
    out0_axi_bresp   = 0;
    out0_axi_bvalid  = 0;
    out0_axi_arready = 0;
    out0_axi_rdata   = 0;
    out0_axi_rresp   = 0;
    out0_axi_rvalid  = 0;
    out1_axi_awready = 0;
    out1_axi_wready  = 0;
    out1_axi_bresp   = 0;
    out1_axi_bvalid  = 0;
    out1_axi_arready = 0;
    out1_axi_rdata   = 0;
    out1_axi_rresp   = 0;
    out1_axi_rvalid  = 0;

    @(posedge axi_clk);
    @(negedge axi_clk);

    axi_rst_n = 1;
    @(posedge axi_clk);
    @(negedge axi_clk);

    switch_sel = 1;
    @(posedge axi_clk);
    @(negedge axi_clk);
    `ASSERT(sel === 1'b1)
    switch_sel = 0;
    @(posedge axi_clk);
    @(negedge axi_clk);
    `ASSERT(sel === 1'b1)

    switch_sel = 1;
    @(posedge axi_clk);
    @(negedge axi_clk);
    `ASSERT(sel === 1'b0)
    switch_sel       = 0;

    in0_axi_awaddr   = 20'h12345;
    in0_axi_awvalid  = 1;
    in0_axi_wdata    = 16'hABCD;
    in0_axi_wstrb    = 2'b11;
    in0_axi_wvalid   = 1;
    out0_axi_awready = 1;
    out0_axi_wready  = 1;
    @(posedge axi_clk);
    @(negedge axi_clk);
    `ASSERT(out0_axi_awaddr === 20'h12345)
    `ASSERT(out0_axi_awvalid === 1'b1)
    `ASSERT(out0_axi_wdata === 16'hABCD)
    `ASSERT(out0_axi_wstrb === 2'b11)
    `ASSERT(out0_axi_wvalid === 1'b1)
    `ASSERT(in0_axi_awready === 1'b1)
    `ASSERT(in0_axi_wready === 1'b1)

    $finish;
  end

endmodule

// verilator lint_on UNUSEDSIGNAL
