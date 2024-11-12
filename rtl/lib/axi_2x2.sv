`ifndef AXI_2X2_V
`define AXI_2X2_V

`include "directives.sv"

module axi_2x2 #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input logic axi_clk,
    input logic axi_resetn,

    // Control interface
    input  logic switch_sel,
    output logic sel,

    // AXI-Lite interface for Input 0
    input  logic [        AXI_ADDR_WIDTH-1:0] in0_axi_awaddr,
    input  logic                              in0_axi_awvalid,
    output logic                              in0_axi_awready,
    input  logic [        AXI_DATA_WIDTH-1:0] in0_axi_wdata,
    input  logic [((AXI_DATA_WIDTH+7)/8)-1:0] in0_axi_wstrb,
    input  logic                              in0_axi_wvalid,
    output logic                              in0_axi_wready,
    output logic [                       1:0] in0_axi_bresp,
    output logic                              in0_axi_bvalid,
    input  logic                              in0_axi_bready,
    input  logic [        AXI_ADDR_WIDTH-1:0] in0_axi_araddr,
    input  logic                              in0_axi_arvalid,
    output logic                              in0_axi_arready,
    output logic [        AXI_DATA_WIDTH-1:0] in0_axi_rdata,
    output logic [                       1:0] in0_axi_rresp,
    output logic                              in0_axi_rvalid,
    input  logic                              in0_axi_rready,

    // AXI-Lite interface for Input 1
    input  logic [        AXI_ADDR_WIDTH-1:0] in1_axi_awaddr,
    input  logic                              in1_axi_awvalid,
    output logic                              in1_axi_awready,
    input  logic [        AXI_DATA_WIDTH-1:0] in1_axi_wdata,
    input  logic [((AXI_DATA_WIDTH+7)/8)-1:0] in1_axi_wstrb,
    input  logic                              in1_axi_wvalid,
    output logic                              in1_axi_wready,
    output logic [                       1:0] in1_axi_bresp,
    output logic                              in1_axi_bvalid,
    input  logic                              in1_axi_bready,
    input  logic [        AXI_ADDR_WIDTH-1:0] in1_axi_araddr,
    input  logic                              in1_axi_arvalid,
    output logic                              in1_axi_arready,
    output logic [        AXI_DATA_WIDTH-1:0] in1_axi_rdata,
    output logic [                       1:0] in1_axi_rresp,
    output logic                              in1_axi_rvalid,
    input  logic                              in1_axi_rready,

    // AXI-Lite interface for Output 0
    output logic [        AXI_ADDR_WIDTH-1:0] out0_axi_awaddr,
    output logic                              out0_axi_awvalid,
    input  logic                              out0_axi_awready,
    output logic [        AXI_DATA_WIDTH-1:0] out0_axi_wdata,
    output logic [((AXI_DATA_WIDTH+7)/8)-1:0] out0_axi_wstrb,
    output logic                              out0_axi_wvalid,
    input  logic                              out0_axi_wready,
    input  logic [                       1:0] out0_axi_bresp,
    input  logic                              out0_axi_bvalid,
    output logic                              out0_axi_bready,
    output logic [        AXI_ADDR_WIDTH-1:0] out0_axi_araddr,
    output logic                              out0_axi_arvalid,
    input  logic                              out0_axi_arready,
    input  logic [        AXI_DATA_WIDTH-1:0] out0_axi_rdata,
    input  logic [                       1:0] out0_axi_rresp,
    input  logic                              out0_axi_rvalid,
    output logic                              out0_axi_rready,

    // AXI-Lite interface for Output 1
    output logic [        AXI_ADDR_WIDTH-1:0] out1_axi_awaddr,
    output logic                              out1_axi_awvalid,
    input  logic                              out1_axi_awready,
    output logic [        AXI_DATA_WIDTH-1:0] out1_axi_wdata,
    output logic [((AXI_DATA_WIDTH+7)/8)-1:0] out1_axi_wstrb,
    output logic                              out1_axi_wvalid,
    input  logic                              out1_axi_wready,
    input  logic [                       1:0] out1_axi_bresp,
    input  logic                              out1_axi_bvalid,
    output logic                              out1_axi_bready,
    output logic [        AXI_ADDR_WIDTH-1:0] out1_axi_araddr,
    output logic                              out1_axi_arvalid,
    input  logic                              out1_axi_arready,
    input  logic [        AXI_DATA_WIDTH-1:0] out1_axi_rdata,
    input  logic [                       1:0] out1_axi_rresp,
    input  logic                              out1_axi_rvalid,
    output logic                              out1_axi_rready
);

  // Selection logic
  always_ff @(posedge axi_clk) begin
    if (!axi_resetn) begin
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
