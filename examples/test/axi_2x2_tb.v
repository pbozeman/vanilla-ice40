`include "testing.v"

`include "axi_2x2.v"

module axi_2x2_tb;

  parameter AXI_ADDR_WIDTH = 20;
  parameter AXI_DATA_WIDTH = 16;

  reg                               axi_clk;
  reg                               axi_rst_n;
  reg                               switch_sel;
  wire                              sel;

  reg  [        AXI_ADDR_WIDTH-1:0] in0_axi_awaddr;
  reg                               in0_axi_awvalid;
  wire                              in0_axi_awready;
  reg  [        AXI_DATA_WIDTH-1:0] in0_axi_wdata;
  reg  [((AXI_DATA_WIDTH+7)/8)-1:0] in0_axi_wstrb;
  reg                               in0_axi_wvalid;
  wire                              in0_axi_wready;
  wire [                       1:0] in0_axi_bresp;
  wire                              in0_axi_bvalid;
  reg                               in0_axi_bready;
  reg  [        AXI_ADDR_WIDTH-1:0] in0_axi_araddr;
  reg                               in0_axi_arvalid;
  wire                              in0_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] in0_axi_rdata;
  wire [                       1:0] in0_axi_rresp;
  wire                              in0_axi_rvalid;
  reg                               in0_axi_rready;

  reg  [        AXI_ADDR_WIDTH-1:0] in1_axi_awaddr;
  reg                               in1_axi_awvalid;
  wire                              in1_axi_awready;
  reg  [        AXI_DATA_WIDTH-1:0] in1_axi_wdata;
  reg  [((AXI_DATA_WIDTH+7)/8)-1:0] in1_axi_wstrb;
  reg                               in1_axi_wvalid;
  wire                              in1_axi_wready;
  wire [                       1:0] in1_axi_bresp;
  wire                              in1_axi_bvalid;
  reg                               in1_axi_bready;
  reg  [        AXI_ADDR_WIDTH-1:0] in1_axi_araddr;
  reg                               in1_axi_arvalid;
  wire                              in1_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] in1_axi_rdata;
  wire [                       1:0] in1_axi_rresp;
  wire                              in1_axi_rvalid;
  reg                               in1_axi_rready;

  wire [        AXI_ADDR_WIDTH-1:0] out0_axi_awaddr;
  wire                              out0_axi_awvalid;
  reg                               out0_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] out0_axi_wdata;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] out0_axi_wstrb;
  wire                              out0_axi_wvalid;
  reg                               out0_axi_wready;
  reg  [                       1:0] out0_axi_bresp;
  reg                               out0_axi_bvalid;
  wire                              out0_axi_bready;
  wire [        AXI_ADDR_WIDTH-1:0] out0_axi_araddr;
  wire                              out0_axi_arvalid;
  reg                               out0_axi_arready;
  reg  [        AXI_DATA_WIDTH-1:0] out0_axi_rdata;
  reg  [                       1:0] out0_axi_rresp;
  reg                               out0_axi_rvalid;
  wire                              out0_axi_rready;

  wire [        AXI_ADDR_WIDTH-1:0] out1_axi_awaddr;
  wire                              out1_axi_awvalid;
  reg                               out1_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] out1_axi_wdata;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] out1_axi_wstrb;
  wire                              out1_axi_wvalid;
  reg                               out1_axi_wready;
  reg  [                       1:0] out1_axi_bresp;
  reg                               out1_axi_bvalid;
  wire                              out1_axi_bready;
  wire [        AXI_ADDR_WIDTH-1:0] out1_axi_araddr;
  wire                              out1_axi_arvalid;
  reg                               out1_axi_arready;
  reg  [        AXI_DATA_WIDTH-1:0] out1_axi_rdata;
  reg  [                       1:0] out1_axi_rresp;
  reg                               out1_axi_rvalid;
  wire                              out1_axi_rready;

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
    axi_rst_n = 1;
    @(posedge axi_clk);

    switch_sel = 1;
    @(posedge axi_clk);
    `ASSERT(sel === 1'b1)
    switch_sel = 0;
    @(posedge axi_clk);
    `ASSERT(sel === 1'b1)

    switch_sel = 1;
    @(posedge axi_clk);
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
