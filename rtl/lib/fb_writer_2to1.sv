`ifndef FB_WRITER_2TO1_V
`define FB_WRITER_2TO1_V

`include "directives.sv"

`include "fb_writer.sv"

module fb_writer_2to1 #(
    parameter PIXEL_BITS     = 12,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input logic clk,
    input logic reset,

    //
    // in0
    //
    input  logic                      in0_axi_tvalid,
    output logic                      in0_axi_tready,
    input  logic [AXI_ADDR_WIDTH-1:0] in0_addr,
    input  logic [    PIXEL_BITS-1:0] in0_color,

    //
    // in1
    //
    input  logic                      in1_axi_tvalid,
    output logic                      in1_axi_tready,
    input  logic [AXI_ADDR_WIDTH-1:0] in1_addr,
    input  logic [    PIXEL_BITS-1:0] in1_color,

    // The AXI interface backing the frame buffer.
    output logic [        AXI_ADDR_WIDTH-1:0] axi_awaddr,
    output logic                              axi_awvalid,
    input  logic                              axi_awready,
    output logic [        AXI_DATA_WIDTH-1:0] axi_wdata,
    output logic [((AXI_DATA_WIDTH+7)/8)-1:0] axi_wstrb,
    output logic                              axi_wvalid,
    input  logic                              axi_wready,
    output logic                              axi_bready,
    input  logic                              axi_bvalid,
    input  logic [                       1:0] axi_bresp
);
  //
  // Concatenate the inputs (one extra the idle channel)
  //
  logic [2:0]                     in_axi_tvalid;
  logic [2:0][AXI_ADDR_WIDTH-1:0] in_addr;
  logic [2:0][    PIXEL_BITS-1:0] in_color;

  assign in_axi_tvalid = {{1'b0}, in1_axi_tvalid, in0_axi_tvalid};
  assign in_addr       = {{AXI_ADDR_WIDTH{1'b0}}, in1_addr, in0_addr};
  assign in_color      = {{PIXEL_BITS{1'b0}}, in1_color, in0_color};

  //
  // Muxed signals
  //
  logic                      fbw_axi_tvalid;
  logic                      fbw_axi_tready;
  logic [AXI_ADDR_WIDTH-1:0] fbw_addr;
  logic [    PIXEL_BITS-1:0] fbw_color;

  //
  // Grant management
  //
  localparam IDLE = 2'b10;

  logic [1:0] grant;
  logic [1:0] next_grant;

  // constant selects in always_comb blocks are not supported by verilator
  logic       v0;
  assign v0 = in_axi_tvalid[0];

  logic v1;
  assign v1 = in_axi_tvalid[1];

  // priority encoder, but with fairness
  always_comb begin
    next_grant = IDLE;

    if (fbw_axi_tvalid && !fbw_axi_tready) begin
      // there is an outstanding txn
      next_grant = grant;
    end else begin
      if (grant == 0) begin
        if (v1) begin
          next_grant = 1;
        end else if (v0) begin
          next_grant = 0;
        end
      end else begin
        if (v0) begin
          next_grant = 0;
        end else if (v1) begin
          next_grant = 1;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      grant <= '0;
    end else begin
      grant <= next_grant;
    end
  end

  //
  // Muxing
  //
  assign fbw_axi_tvalid = in_axi_tvalid[grant];
  assign fbw_addr       = in_addr[grant];
  assign fbw_color      = in_color[grant];

  always_comb begin
    in0_axi_tready = grant == 2'b00 ? fbw_axi_tready : 1'b0;
    in1_axi_tready = grant == 2'b01 ? fbw_axi_tready : 1'b0;
  end

  fb_writer #(
      .PIXEL_BITS    (PIXEL_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) fb_writer_inst (
      .clk  (clk),
      .reset(reset),

      .axi_tvalid(fbw_axi_tvalid),
      .axi_tready(fbw_axi_tready),

      .addr (fbw_addr),
      .color(fbw_color),

      .axi_awaddr (axi_awaddr),
      .axi_awvalid(axi_awvalid),
      .axi_awready(axi_awready),
      .axi_wdata  (axi_wdata),
      .axi_wstrb  (axi_wstrb),
      .axi_wvalid (axi_wvalid),
      .axi_wready (axi_wready),
      .axi_bvalid (axi_bvalid),
      .axi_bready (axi_bready),
      .axi_bresp  (axi_bresp)
  );

endmodule

`endif
