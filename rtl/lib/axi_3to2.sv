`ifndef AXI_3TO2_V
`define AXI_3TO2_V

`include "directives.sv"

// AXI-Lite interconnect with 3 managers and 2 subordinates.
//
// Managers are selected with priority encoding, with 0 as the
// highest pri and 2 as the lowest.
//
// Subordinates are routed with even addresses to 0 and odd to 1.
module axi_3to2 #(
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

    // AXI-Lite interface for Output 0
    output logic [AXI_ADDR_WIDTH-1:0] out0_axi_awaddr,
    output logic                      out0_axi_awvalid,
    input  logic                      out0_axi_awready,
    output logic [AXI_DATA_WIDTH-1:0] out0_axi_wdata,
    output logic [AXI_STRB_WIDTH-1:0] out0_axi_wstrb,
    output logic                      out0_axi_wvalid,
    input  logic                      out0_axi_wready,
    input  logic [               1:0] out0_axi_bresp,
    input  logic                      out0_axi_bvalid,
    output logic                      out0_axi_bready,
    output logic [AXI_ADDR_WIDTH-1:0] out0_axi_araddr,
    output logic                      out0_axi_arvalid,
    input  logic                      out0_axi_arready,
    input  logic [AXI_DATA_WIDTH-1:0] out0_axi_rdata,
    input  logic [               1:0] out0_axi_rresp,
    input  logic                      out0_axi_rvalid,
    output logic                      out0_axi_rready,

    // AXI-Lite interface for Output 1
    output logic [AXI_ADDR_WIDTH-1:0] out1_axi_awaddr,
    output logic                      out1_axi_awvalid,
    input  logic                      out1_axi_awready,
    output logic [AXI_DATA_WIDTH-1:0] out1_axi_wdata,
    output logic [AXI_STRB_WIDTH-1:0] out1_axi_wstrb,
    output logic                      out1_axi_wvalid,
    input  logic                      out1_axi_wready,
    input  logic [               1:0] out1_axi_bresp,
    input  logic                      out1_axi_bvalid,
    output logic                      out1_axi_bready,
    output logic [AXI_ADDR_WIDTH-1:0] out1_axi_araddr,
    output logic                      out1_axi_arvalid,
    input  logic                      out1_axi_arready,
    input  logic [AXI_DATA_WIDTH-1:0] out1_axi_rdata,
    input  logic [               1:0] out1_axi_rresp,
    input  logic                      out1_axi_rvalid,
    output logic                      out1_axi_rready
);

endmodule

`endif
