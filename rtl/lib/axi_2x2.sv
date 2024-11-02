`ifndef AXI_2X2_V
`define AXI_2X2_V

`include "directives.sv"

module axi_2x2 #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input wire axi_clk,
    input wire axi_rst_n,

    // Control interface
    input  wire switch_sel,
    output reg  sel,

    // AXI-Lite interface for Input 0
    input  wire [        AXI_ADDR_WIDTH-1:0] in0_axi_awaddr,
    input  wire                              in0_axi_awvalid,
    output wire                              in0_axi_awready,
    input  wire [        AXI_DATA_WIDTH-1:0] in0_axi_wdata,
    input  wire [((AXI_DATA_WIDTH+7)/8)-1:0] in0_axi_wstrb,
    input  wire                              in0_axi_wvalid,
    output wire                              in0_axi_wready,
    output wire [                       1:0] in0_axi_bresp,
    output wire                              in0_axi_bvalid,
    input  wire                              in0_axi_bready,
    input  wire [        AXI_ADDR_WIDTH-1:0] in0_axi_araddr,
    input  wire                              in0_axi_arvalid,
    output wire                              in0_axi_arready,
    output wire [        AXI_DATA_WIDTH-1:0] in0_axi_rdata,
    output wire [                       1:0] in0_axi_rresp,
    output wire                              in0_axi_rvalid,
    input  wire                              in0_axi_rready,

    // AXI-Lite interface for Input 1
    input  wire [        AXI_ADDR_WIDTH-1:0] in1_axi_awaddr,
    input  wire                              in1_axi_awvalid,
    output wire                              in1_axi_awready,
    input  wire [        AXI_DATA_WIDTH-1:0] in1_axi_wdata,
    input  wire [((AXI_DATA_WIDTH+7)/8)-1:0] in1_axi_wstrb,
    input  wire                              in1_axi_wvalid,
    output wire                              in1_axi_wready,
    output wire [                       1:0] in1_axi_bresp,
    output wire                              in1_axi_bvalid,
    input  wire                              in1_axi_bready,
    input  wire [        AXI_ADDR_WIDTH-1:0] in1_axi_araddr,
    input  wire                              in1_axi_arvalid,
    output wire                              in1_axi_arready,
    output wire [        AXI_DATA_WIDTH-1:0] in1_axi_rdata,
    output wire [                       1:0] in1_axi_rresp,
    output wire                              in1_axi_rvalid,
    input  wire                              in1_axi_rready,

    // AXI-Lite interface for Output 0
    output wire [        AXI_ADDR_WIDTH-1:0] out0_axi_awaddr,
    output wire                              out0_axi_awvalid,
    input  wire                              out0_axi_awready,
    output wire [        AXI_DATA_WIDTH-1:0] out0_axi_wdata,
    output wire [((AXI_DATA_WIDTH+7)/8)-1:0] out0_axi_wstrb,
    output wire                              out0_axi_wvalid,
    input  wire                              out0_axi_wready,
    input  wire [                       1:0] out0_axi_bresp,
    input  wire                              out0_axi_bvalid,
    output wire                              out0_axi_bready,
    output wire [        AXI_ADDR_WIDTH-1:0] out0_axi_araddr,
    output wire                              out0_axi_arvalid,
    input  wire                              out0_axi_arready,
    input  wire [        AXI_DATA_WIDTH-1:0] out0_axi_rdata,
    input  wire [                       1:0] out0_axi_rresp,
    input  wire                              out0_axi_rvalid,
    output wire                              out0_axi_rready,

    // AXI-Lite interface for Output 1
    output wire [        AXI_ADDR_WIDTH-1:0] out1_axi_awaddr,
    output wire                              out1_axi_awvalid,
    input  wire                              out1_axi_awready,
    output wire [        AXI_DATA_WIDTH-1:0] out1_axi_wdata,
    output wire [((AXI_DATA_WIDTH+7)/8)-1:0] out1_axi_wstrb,
    output wire                              out1_axi_wvalid,
    input  wire                              out1_axi_wready,
    input  wire [                       1:0] out1_axi_bresp,
    input  wire                              out1_axi_bvalid,
    output wire                              out1_axi_bready,
    output wire [        AXI_ADDR_WIDTH-1:0] out1_axi_araddr,
    output wire                              out1_axi_arvalid,
    input  wire                              out1_axi_arready,
    input  wire [        AXI_DATA_WIDTH-1:0] out1_axi_rdata,
    input  wire [                       1:0] out1_axi_rresp,
    input  wire                              out1_axi_rvalid,
    output wire                              out1_axi_rready
);

  // Selection logic
  always @(posedge axi_clk) begin
    if (!axi_rst_n) begin
      sel <= 0;
    end else if (switch_sel) begin
      sel <= ~sel;
    end
  end

  // Switch logic for Input 0
  assign in0_axi_awready  = !sel ? out0_axi_awready : out1_axi_awready;
  assign in0_axi_wready   = !sel ? out0_axi_wready : out1_axi_wready;
  assign in0_axi_bresp    = !sel ? out0_axi_bresp : out1_axi_bresp;
  assign in0_axi_bvalid   = !sel ? out0_axi_bvalid : out1_axi_bvalid;
  assign in0_axi_arready  = !sel ? out0_axi_arready : out1_axi_arready;
  assign in0_axi_rdata    = !sel ? out0_axi_rdata : out1_axi_rdata;
  assign in0_axi_rresp    = !sel ? out0_axi_rresp : out1_axi_rresp;
  assign in0_axi_rvalid   = !sel ? out0_axi_rvalid : out1_axi_rvalid;

  // Switch logic for Input 1
  assign in1_axi_awready  = sel ? out0_axi_awready : out1_axi_awready;
  assign in1_axi_wready   = sel ? out0_axi_wready : out1_axi_wready;
  assign in1_axi_bresp    = sel ? out0_axi_bresp : out1_axi_bresp;
  assign in1_axi_bvalid   = sel ? out0_axi_bvalid : out1_axi_bvalid;
  assign in1_axi_arready  = sel ? out0_axi_arready : out1_axi_arready;
  assign in1_axi_rdata    = sel ? out0_axi_rdata : out1_axi_rdata;
  assign in1_axi_rresp    = sel ? out0_axi_rresp : out1_axi_rresp;
  assign in1_axi_rvalid   = sel ? out0_axi_rvalid : out1_axi_rvalid;

  // Switch logic for Output 0
  assign out0_axi_awaddr  = !sel ? in0_axi_awaddr : in1_axi_awaddr;
  assign out0_axi_awvalid = !sel ? in0_axi_awvalid : in1_axi_awvalid;
  assign out0_axi_wdata   = !sel ? in0_axi_wdata : in1_axi_wdata;
  assign out0_axi_wstrb   = !sel ? in0_axi_wstrb : in1_axi_wstrb;
  assign out0_axi_wvalid  = !sel ? in0_axi_wvalid : in1_axi_wvalid;
  assign out0_axi_bready  = !sel ? in0_axi_bready : in1_axi_bready;
  assign out0_axi_araddr  = !sel ? in0_axi_araddr : in1_axi_araddr;
  assign out0_axi_arvalid = !sel ? in0_axi_arvalid : in1_axi_arvalid;
  assign out0_axi_rready  = !sel ? in0_axi_rready : in1_axi_rready;

  // Switch logic for Output 1
  assign out1_axi_awaddr  = sel ? in0_axi_awaddr : in1_axi_awaddr;
  assign out1_axi_awvalid = sel ? in0_axi_awvalid : in1_axi_awvalid;
  assign out1_axi_wdata   = sel ? in0_axi_wdata : in1_axi_wdata;
  assign out1_axi_wstrb   = sel ? in0_axi_wstrb : in1_axi_wstrb;
  assign out1_axi_wvalid  = sel ? in0_axi_wvalid : in1_axi_wvalid;
  assign out1_axi_bready  = sel ? in0_axi_bready : in1_axi_bready;
  assign out1_axi_araddr  = sel ? in0_axi_araddr : in1_axi_araddr;
  assign out1_axi_arvalid = sel ? in0_axi_arvalid : in1_axi_arvalid;
  assign out1_axi_rready  = sel ? in0_axi_rready : in1_axi_rready;

endmodule

`endif
