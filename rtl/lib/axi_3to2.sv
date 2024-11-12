`ifndef AXI_3TO2_V
`define AXI_3TO2_V

`include "directives.sv"

// AXI-Lite interconnect with 3 managers and 2 subordinates.
//
// Managers are selected with priority encoding, with 0 as the
// highest pri and 2 as the lowest.
//
// Subordinates are routed with even addresses to 0 and odd to 1.
// verilator lint_off UNUSEDSIGNAL
// verilator lint_off UNDRIVEN
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
  // Concatenate the inputs. We will later index into these concatenated
  // buses for muxing based on the grants. There is one extra position
  // at the highest index, and holds 0s for CHANNEL_IDLE. This is how
  // 1'b0 are sent back for the relevant ready signals back to the managers
  // when they don't have a grant.
  logic [3:0][AXI_ADDR_WIDTH-1:0] all_axi_awaddr;
  logic [3:0]                     all_axi_awvalid;
  logic [3:0][AXI_DATA_WIDTH-1:0] all_axi_wdata;
  logic [3:0][AXI_STRB_WIDTH-1:0] all_axi_wstrb;
  logic [3:0]                     all_axi_wvalid;
  logic [3:0]                     all_axi_bready;

  assign all_axi_awaddr = {
    {AXI_ADDR_WIDTH{1'b0}}, in2_axi_awaddr, in1_axi_awaddr, in0_axi_awaddr
  };
  assign all_axi_awvalid = {
    1'b0, in2_axi_awvalid, in1_axi_awvalid, in0_axi_awvalid
  };
  assign all_axi_wdata = {
    {AXI_DATA_WIDTH{1'b0}}, in2_axi_wdata, in1_axi_wdata, in0_axi_wdata
  };
  assign all_axi_wstrb = {
    {AXI_STRB_WIDTH{1'b0}}, in2_axi_wstrb, in1_axi_wstrb, in0_axi_wstrb
  };
  assign all_axi_wvalid = {
    1'b0, in2_axi_wvalid, in1_axi_wvalid, in0_axi_wvalid
  };
  assign all_axi_bready = {
    1'b0, in2_axi_bready, in1_axi_bready, in0_axi_bready
  };

  // outN_dst_waddr: manager addr is to be routed to subordinate N
  // outN_greq: manager is requesting a grant to subordinate N
  logic [2:0] out0_dst_waddr;
  logic [2:0] out0_greq;

  // The grants. Set to CHANNEL_IDLE if no grant is active.
  localparam CHANNEL_IDLE = 2'b11;
  logic [1:0] out0_grant;
  logic [1:0] out1_grant;

  assign out0_dst_waddr = {
    ~in2_axi_awaddr[0], ~in1_axi_awaddr[0], ~in0_axi_awaddr[0]
  };

  assign out0_greq = all_axi_awvalid & out0_dst_waddr;

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      out0_grant <= CHANNEL_IDLE;
    end else begin
      // TODO: release grant

      if (out0_grant == CHANNEL_IDLE) begin
        out0_grant <= CHANNEL_IDLE;
        case (1'b1)
          out0_greq[0]: out0_grant <= 0;
          out0_greq[1]: out0_grant <= 1;
          out0_greq[2]: out0_grant <= 2;
        endcase
      end
    end
  end

  //
  // out0 mux
  //
  assign out0_axi_awaddr  = all_axi_awaddr[out0_grant];
  assign out0_axi_awvalid = all_axi_awvalid[out0_grant];
  assign out0_axi_wdata   = all_axi_wdata[out0_grant];
  assign out0_axi_wstrb   = all_axi_wstrb[out0_grant];
  assign out0_axi_wvalid  = all_axi_wvalid[out0_grant];
  assign out0_axi_bready  = all_axi_bready[out0_grant];

endmodule
// verilator lint_on UNUSEDSIGNAL
// verilator lint_on UNDRIVEN

`endif
