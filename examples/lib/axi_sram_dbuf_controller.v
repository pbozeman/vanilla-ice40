`ifndef AXI_SRAM_DBUF_CONTROLLER_V
`define AXI_SRAM_DBUF_CONTROLLER_V

`include "directives.v"

`include "axi_2x2.v"
`include "axi_sram_controller.v"

// TBD: this still needs careful coordination by the user of the module
// of when they do the switch. If axi transactions are in flight, the bus
// might hang because axi_bready or axi_rready will go low while a txn
// is in progress. This could be addressed in this module. Although,
// it may not be a good use of resources, so it may be best to leave
// it as is.
module axi_sram_dbuf_controller #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    // core signals
    input wire clk,
    input wire reset,

    // switch producer/consumer to alternate sram
    input wire switch,

    // producer interface
    input  wire [        AXI_ADDR_WIDTH-1:0] prod_axi_awaddr,
    input  wire                              prod_axi_awvalid,
    output wire                              prod_axi_awready,
    input  wire [        AXI_DATA_WIDTH-1:0] prod_axi_wdata,
    input  wire                              prod_axi_wvalid,
    input  wire [((AXI_DATA_WIDTH+7)/8)-1:0] prod_axi_wstrb,
    output wire                              prod_axi_wready,
    input  wire                              prod_axi_bready,
    output wire                              prod_axi_bvalid,
    output wire [                       1:0] prod_axi_bresp,

    // consumer interface
    input  wire [AXI_ADDR_WIDTH-1:0] cons_axi_araddr,
    input  wire                      cons_axi_arvalid,
    output wire                      cons_axi_arready,
    output wire [AXI_DATA_WIDTH-1:0] cons_axi_rdata,
    output wire                      cons_axi_rvalid,
    input  wire                      cons_axi_rready,
    output wire [               1:0] cons_axi_rresp,

    // sram0 controller to io pins
    output wire [AXI_ADDR_WIDTH-1:0] sram0_io_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram0_io_data,
    output wire                      sram0_io_we_n,
    output wire                      sram0_io_oe_n,
    output wire                      sram0_io_ce_n,

    // sram1 controller to io pins
    output wire [AXI_ADDR_WIDTH-1:0] sram1_io_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram1_io_data,
    output wire                      sram1_io_we_n,
    output wire                      sram1_io_oe_n,
    output wire                      sram1_io_ce_n
);
  //
  // Internal producer signals
  //
  wire                              prod_axi_arvalid;

  // verilator lint_off UNUSEDSIGNAL
  wire [        AXI_ADDR_WIDTH-1:0] prod_axi_araddr;
  wire                              prod_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] prod_axi_rdata;
  wire                              prod_axi_rvalid;
  wire                              prod_axi_rready;
  wire [                       1:0] prod_axi_rresp;
  // verilator lint_on UNUSEDSIGNAL

  //
  // Internal consumer signals
  //
  wire                              cons_axi_awvalid;
  wire                              cons_axi_wvalid;

  // verilator lint_off UNUSEDSIGNAL
  wire [        AXI_ADDR_WIDTH-1:0] cons_axi_awaddr;
  wire                              cons_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] cons_axi_wdata;
  wire                              cons_axi_wready;
  wire                              cons_axi_bready;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] cons_axi_wstrb;
  wire [                       1:0] cons_axi_bresp;
  wire                              cons_axi_bvalid;
  // verilator lint_on UNUSEDSIGNAL

  // SRAM 0
  wire [        AXI_ADDR_WIDTH-1:0] sram0_axi_awaddr;
  wire                              sram0_axi_awvalid;
  wire                              sram0_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] sram0_axi_wdata;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] sram0_axi_wstrb;
  wire                              sram0_axi_wvalid;
  wire                              sram0_axi_wready;
  wire [                       1:0] sram0_axi_bresp;
  wire                              sram0_axi_bvalid;
  wire                              sram0_axi_bready;
  wire [        AXI_ADDR_WIDTH-1:0] sram0_axi_araddr;
  wire                              sram0_axi_arvalid;
  wire                              sram0_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] sram0_axi_rdata;
  wire [                       1:0] sram0_axi_rresp;
  wire                              sram0_axi_rvalid;
  wire                              sram0_axi_rready;

  // SRAM 1
  wire [        AXI_ADDR_WIDTH-1:0] sram1_axi_awaddr;
  wire                              sram1_axi_awvalid;
  wire                              sram1_axi_awready;
  wire [        AXI_DATA_WIDTH-1:0] sram1_axi_wdata;
  wire [((AXI_DATA_WIDTH+7)/8)-1:0] sram1_axi_wstrb;
  wire                              sram1_axi_wvalid;
  wire                              sram1_axi_wready;
  wire [                       1:0] sram1_axi_bresp;
  wire                              sram1_axi_bvalid;
  wire                              sram1_axi_bready;
  wire [        AXI_ADDR_WIDTH-1:0] sram1_axi_araddr;
  wire                              sram1_axi_arvalid;
  wire                              sram1_axi_arready;
  wire [        AXI_DATA_WIDTH-1:0] sram1_axi_rdata;
  wire [                       1:0] sram1_axi_rresp;
  wire                              sram1_axi_rvalid;
  wire                              sram1_axi_rready;

  // verilator lint_off UNUSEDSIGNAL
  wire                              a2x2_sel;
  // verilator lint_on UNUSEDSIGNAL

  // set bits for unused channels
  assign prod_axi_arvalid = 1'b0;
  assign prod_axi_araddr  = 0;
  assign prod_axi_rready  = 1'b0;

  assign cons_axi_awvalid = 1'b0;
  assign cons_axi_awaddr  = 0;
  assign cons_axi_wvalid  = 1'b0;
  assign cons_axi_wdata   = 0;
  assign cons_axi_bready  = 1'b0;
  assign cons_axi_wstrb   = {((AXI_DATA_WIDTH + 7) / 8) {1'b1}};

  axi_2x2 #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) dbuf (
      .axi_clk  (clk),
      .axi_rst_n(~reset),

      // Control interface
      .switch_sel(switch),
      .sel       (a2x2_sel),

      // Producer
      .in0_axi_awaddr (prod_axi_awaddr),
      .in0_axi_awvalid(prod_axi_awvalid),
      .in0_axi_awready(prod_axi_awready),
      .in0_axi_wdata  (prod_axi_wdata),
      .in0_axi_wstrb  (prod_axi_wstrb),
      .in0_axi_wvalid (prod_axi_wvalid),
      .in0_axi_wready (prod_axi_wready),
      .in0_axi_bresp  (prod_axi_bresp),
      .in0_axi_bvalid (prod_axi_bvalid),
      .in0_axi_bready (prod_axi_bready),
      .in0_axi_araddr (prod_axi_araddr),
      .in0_axi_arvalid(prod_axi_arvalid),
      .in0_axi_arready(prod_axi_arready),
      .in0_axi_rdata  (prod_axi_rdata),
      .in0_axi_rresp  (prod_axi_rresp),
      .in0_axi_rvalid (prod_axi_rvalid),
      .in0_axi_rready (prod_axi_rready),

      // Consumer
      .in1_axi_awaddr (cons_axi_awaddr),
      .in1_axi_awvalid(cons_axi_awvalid),
      .in1_axi_awready(cons_axi_awready),
      .in1_axi_wdata  (cons_axi_wdata),
      .in1_axi_wstrb  (cons_axi_wstrb),
      .in1_axi_wvalid (cons_axi_wvalid),
      .in1_axi_wready (cons_axi_wready),
      .in1_axi_bresp  (cons_axi_bresp),
      .in1_axi_bvalid (cons_axi_bvalid),
      .in1_axi_bready (cons_axi_bready),
      .in1_axi_araddr (cons_axi_araddr),
      .in1_axi_arvalid(cons_axi_arvalid),
      .in1_axi_arready(cons_axi_arready),
      .in1_axi_rdata  (cons_axi_rdata),
      .in1_axi_rresp  (cons_axi_rresp),
      .in1_axi_rvalid (cons_axi_rvalid),
      .in1_axi_rready (cons_axi_rready),

      // SRAM 0
      .out0_axi_awaddr (sram0_axi_awaddr),
      .out0_axi_awvalid(sram0_axi_awvalid),
      .out0_axi_awready(sram0_axi_awready),
      .out0_axi_wdata  (sram0_axi_wdata),
      .out0_axi_wstrb  (sram0_axi_wstrb),
      .out0_axi_wvalid (sram0_axi_wvalid),
      .out0_axi_wready (sram0_axi_wready),
      .out0_axi_bresp  (sram0_axi_bresp),
      .out0_axi_bvalid (sram0_axi_bvalid),
      .out0_axi_bready (sram0_axi_bready),
      .out0_axi_araddr (sram0_axi_araddr),
      .out0_axi_arvalid(sram0_axi_arvalid),
      .out0_axi_arready(sram0_axi_arready),
      .out0_axi_rdata  (sram0_axi_rdata),
      .out0_axi_rresp  (sram0_axi_rresp),
      .out0_axi_rvalid (sram0_axi_rvalid),
      .out0_axi_rready (sram0_axi_rready),

      // SRAM 1
      .out1_axi_awaddr (sram1_axi_awaddr),
      .out1_axi_awvalid(sram1_axi_awvalid),
      .out1_axi_awready(sram1_axi_awready),
      .out1_axi_wdata  (sram1_axi_wdata),
      .out1_axi_wstrb  (sram1_axi_wstrb),
      .out1_axi_wvalid (sram1_axi_wvalid),
      .out1_axi_wready (sram1_axi_wready),
      .out1_axi_bresp  (sram1_axi_bresp),
      .out1_axi_bvalid (sram1_axi_bvalid),
      .out1_axi_bready (sram1_axi_bready),
      .out1_axi_araddr (sram1_axi_araddr),
      .out1_axi_arvalid(sram1_axi_arvalid),
      .out1_axi_arready(sram1_axi_arready),
      .out1_axi_rdata  (sram1_axi_rdata),
      .out1_axi_rresp  (sram1_axi_rresp),
      .out1_axi_rvalid (sram1_axi_rvalid),
      .out1_axi_rready (sram1_axi_rready)
  );

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl_0 (
      .axi_clk     (clk),
      .axi_resetn  (~reset),
      .axi_awaddr  (sram0_axi_awaddr),
      .axi_awvalid (sram0_axi_awvalid),
      .axi_awready (sram0_axi_awready),
      .axi_wdata   (sram0_axi_wdata),
      .axi_wstrb   (sram0_axi_wstrb),
      .axi_wvalid  (sram0_axi_wvalid),
      .axi_wready  (sram0_axi_wready),
      .axi_bresp   (sram0_axi_bresp),
      .axi_bvalid  (sram0_axi_bvalid),
      .axi_bready  (sram0_axi_bready),
      .axi_araddr  (sram0_axi_araddr),
      .axi_arvalid (sram0_axi_arvalid),
      .axi_arready (sram0_axi_arready),
      .axi_rdata   (sram0_axi_rdata),
      .axi_rresp   (sram0_axi_rresp),
      .axi_rvalid  (sram0_axi_rvalid),
      .axi_rready  (sram0_axi_rready),
      .sram_io_addr(sram0_io_addr),
      .sram_io_data(sram0_io_data),
      .sram_io_we_n(sram0_io_we_n),
      .sram_io_oe_n(sram0_io_oe_n),
      .sram_io_ce_n(sram0_io_ce_n)
  );

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl_1 (
      .axi_clk     (clk),
      .axi_resetn  (~reset),
      .axi_awaddr  (sram1_axi_awaddr),
      .axi_awvalid (sram1_axi_awvalid),
      .axi_awready (sram1_axi_awready),
      .axi_wdata   (sram1_axi_wdata),
      .axi_wstrb   (sram1_axi_wstrb),
      .axi_wvalid  (sram1_axi_wvalid),
      .axi_wready  (sram1_axi_wready),
      .axi_bresp   (sram1_axi_bresp),
      .axi_bvalid  (sram1_axi_bvalid),
      .axi_bready  (sram1_axi_bready),
      .axi_araddr  (sram1_axi_araddr),
      .axi_arvalid (sram1_axi_arvalid),
      .axi_arready (sram1_axi_arready),
      .axi_rdata   (sram1_axi_rdata),
      .axi_rresp   (sram1_axi_rresp),
      .axi_rvalid  (sram1_axi_rvalid),
      .axi_rready  (sram1_axi_rready),
      .sram_io_addr(sram1_io_addr),
      .sram_io_data(sram1_io_data),
      .sram_io_we_n(sram1_io_we_n),
      .sram_io_oe_n(sram1_io_oe_n),
      .sram_io_ce_n(sram1_io_ce_n)
  );

endmodule

`endif