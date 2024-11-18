`ifndef AXI_SRAM_3TO2_V
`define AXI_SRAM_3TO2_V

`include "directives.sv"

`include "axi_3to2.sv"
`include "axi_sram_controller.sv"

module axi_sram_3to2 #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    // AXI-Lite interface for Input 0
    input  logic [AXI_ADDR_WIDTH-1:0] in0_axi_awaddr,
    input  logic                      in0_axi_awvalid,
    output logic                      in0_axi_awready,
    input  logic [AXI_DATA_WIDTH-1:0] in0_axi_wdata,
    input  logic [AXI_STRB_WIDTH-1:0] in0_axi_wstrb,
    input  logic                      in0_axi_wvalid,
    output logic                      in0_axi_wready,
    output logic [               1:0] in0_axi_bresp,
    output logic                      in0_axi_bvalid,
    input  logic                      in0_axi_bready,
    input  logic [AXI_ADDR_WIDTH-1:0] in0_axi_araddr,
    input  logic                      in0_axi_arvalid,
    output logic                      in0_axi_arready,
    output logic [AXI_DATA_WIDTH-1:0] in0_axi_rdata,
    output logic [               1:0] in0_axi_rresp,
    output logic                      in0_axi_rvalid,
    input  logic                      in0_axi_rready,

    // AXI-Lite interface for Input 1
    input  logic [AXI_ADDR_WIDTH-1:0] in1_axi_awaddr,
    input  logic                      in1_axi_awvalid,
    output logic                      in1_axi_awready,
    input  logic [AXI_DATA_WIDTH-1:0] in1_axi_wdata,
    input  logic [AXI_STRB_WIDTH-1:0] in1_axi_wstrb,
    input  logic                      in1_axi_wvalid,
    output logic                      in1_axi_wready,
    output logic [               1:0] in1_axi_bresp,
    output logic                      in1_axi_bvalid,
    input  logic                      in1_axi_bready,
    input  logic [AXI_ADDR_WIDTH-1:0] in1_axi_araddr,
    input  logic                      in1_axi_arvalid,
    output logic                      in1_axi_arready,
    output logic [AXI_DATA_WIDTH-1:0] in1_axi_rdata,
    output logic [               1:0] in1_axi_rresp,
    output logic                      in1_axi_rvalid,
    input  logic                      in1_axi_rready,

    // AXI-Lite interface for Input 2
    input  logic [AXI_ADDR_WIDTH-1:0] in2_axi_awaddr,
    input  logic                      in2_axi_awvalid,
    output logic                      in2_axi_awready,
    input  logic [AXI_DATA_WIDTH-1:0] in2_axi_wdata,
    input  logic [AXI_STRB_WIDTH-1:0] in2_axi_wstrb,
    input  logic                      in2_axi_wvalid,
    output logic                      in2_axi_wready,
    output logic [               1:0] in2_axi_bresp,
    output logic                      in2_axi_bvalid,
    input  logic                      in2_axi_bready,
    input  logic [AXI_ADDR_WIDTH-1:0] in2_axi_araddr,
    input  logic                      in2_axi_arvalid,
    output logic                      in2_axi_arready,
    output logic [AXI_DATA_WIDTH-1:0] in2_axi_rdata,
    output logic [               1:0] in2_axi_rresp,
    output logic                      in2_axi_rvalid,
    input  logic                      in2_axi_rready,

    // sram0 controller to io pins
    output logic [AXI_ADDR_WIDTH-1:0] sram0_io_addr,
    inout  wire  [AXI_DATA_WIDTH-1:0] sram0_io_data,
    output logic                      sram0_io_we_n,
    output logic                      sram0_io_oe_n,
    output logic                      sram0_io_ce_n,

    // sram1 controller to io pins
    output logic [AXI_ADDR_WIDTH-1:0] sram1_io_addr,
    inout  wire  [AXI_DATA_WIDTH-1:0] sram1_io_data,
    output logic                      sram1_io_we_n,
    output logic                      sram1_io_oe_n,
    output logic                      sram1_io_ce_n
);
  // SRAM 0
  logic [        AXI_ADDR_WIDTH-1:0] sram0_axi_awaddr;
  logic                              sram0_axi_awvalid;
  logic                              sram0_axi_awready;
  logic [        AXI_DATA_WIDTH-1:0] sram0_axi_wdata;
  logic [((AXI_DATA_WIDTH+7)/8)-1:0] sram0_axi_wstrb;
  logic                              sram0_axi_wvalid;
  logic                              sram0_axi_wready;
  logic [                       1:0] sram0_axi_bresp;
  logic                              sram0_axi_bvalid;
  logic                              sram0_axi_bready;
  logic [        AXI_ADDR_WIDTH-1:0] sram0_axi_araddr;
  logic                              sram0_axi_arvalid;
  logic                              sram0_axi_arready;
  logic [        AXI_DATA_WIDTH-1:0] sram0_axi_rdata;
  logic [                       1:0] sram0_axi_rresp;
  logic                              sram0_axi_rvalid;
  logic                              sram0_axi_rready;

  // SRAM 1
  logic [        AXI_ADDR_WIDTH-1:0] sram1_axi_awaddr;
  logic                              sram1_axi_awvalid;
  logic                              sram1_axi_awready;
  logic [        AXI_DATA_WIDTH-1:0] sram1_axi_wdata;
  logic [((AXI_DATA_WIDTH+7)/8)-1:0] sram1_axi_wstrb;
  logic                              sram1_axi_wvalid;
  logic                              sram1_axi_wready;
  logic [                       1:0] sram1_axi_bresp;
  logic                              sram1_axi_bvalid;
  logic                              sram1_axi_bready;
  logic [        AXI_ADDR_WIDTH-1:0] sram1_axi_araddr;
  logic                              sram1_axi_arvalid;
  logic                              sram1_axi_arready;
  logic [        AXI_DATA_WIDTH-1:0] sram1_axi_rdata;
  logic [                       1:0] sram1_axi_rresp;
  logic                              sram1_axi_rvalid;
  logic                              sram1_axi_rready;

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl_0 (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
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
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
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

  axi_3to2 #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) arbiter (
      .axi_clk   (axi_clk),
      .axi_resetn(axi_resetn),

      .in0_axi_awaddr (in0_axi_awaddr),
      .in0_axi_awvalid(in0_axi_awvalid),
      .in0_axi_awready(in0_axi_awready),
      .in0_axi_wdata  (in0_axi_wdata),
      .in0_axi_wstrb  (in0_axi_wstrb),
      .in0_axi_wvalid (in0_axi_wvalid),
      .in0_axi_wready (in0_axi_wready),
      .in0_axi_bresp  (in0_axi_bresp),
      .in0_axi_bvalid (in0_axi_bvalid),
      .in0_axi_bready (in0_axi_bready),
      .in0_axi_araddr (in0_axi_araddr),
      .in0_axi_arvalid(in0_axi_arvalid),
      .in0_axi_arready(in0_axi_arready),
      .in0_axi_rdata  (in0_axi_rdata),
      .in0_axi_rresp  (in0_axi_rresp),
      .in0_axi_rvalid (in0_axi_rvalid),
      .in0_axi_rready (in0_axi_rready),

      .in1_axi_awaddr (in1_axi_awaddr),
      .in1_axi_awvalid(in1_axi_awvalid),
      .in1_axi_awready(in1_axi_awready),
      .in1_axi_wdata  (in1_axi_wdata),
      .in1_axi_wstrb  (in1_axi_wstrb),
      .in1_axi_wvalid (in1_axi_wvalid),
      .in1_axi_wready (in1_axi_wready),
      .in1_axi_bresp  (in1_axi_bresp),
      .in1_axi_bvalid (in1_axi_bvalid),
      .in1_axi_bready (in1_axi_bready),
      .in1_axi_araddr (in1_axi_araddr),
      .in1_axi_arvalid(in1_axi_arvalid),
      .in1_axi_arready(in1_axi_arready),
      .in1_axi_rdata  (in1_axi_rdata),
      .in1_axi_rresp  (in1_axi_rresp),
      .in1_axi_rvalid (in1_axi_rvalid),
      .in1_axi_rready (in1_axi_rready),

      .in2_axi_awaddr (in2_axi_awaddr),
      .in2_axi_awvalid(in2_axi_awvalid),
      .in2_axi_awready(in2_axi_awready),
      .in2_axi_wdata  (in2_axi_wdata),
      .in2_axi_wstrb  (in2_axi_wstrb),
      .in2_axi_wvalid (in2_axi_wvalid),
      .in2_axi_wready (in2_axi_wready),
      .in2_axi_bresp  (in2_axi_bresp),
      .in2_axi_bvalid (in2_axi_bvalid),
      .in2_axi_bready (in2_axi_bready),
      .in2_axi_araddr (in2_axi_araddr),
      .in2_axi_arvalid(in2_axi_arvalid),
      .in2_axi_arready(in2_axi_arready),
      .in2_axi_rdata  (in2_axi_rdata),
      .in2_axi_rresp  (in2_axi_rresp),
      .in2_axi_rvalid (in2_axi_rvalid),
      .in2_axi_rready (in2_axi_rready),

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

endmodule

`endif
