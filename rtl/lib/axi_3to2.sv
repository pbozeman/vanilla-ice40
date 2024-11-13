`ifndef AXI_3TO2_V
`define AXI_3TO2_V

`include "directives.sv"

`include "sync_fifo.sv"
`include "txn_done.sv"

// AXI-Lite interconnect with 3 managers and 2 subordinates.
//
// Managers are selected with priority encoding, with 0 as the
// highest pri and 2 as the lowest, but, if anyone else is waiting
// for the grant, the current holder will give it up.
//
// Write and Read grants are handled separately for a few reasons:
//  * Simplicity: it removes the need to track if a read, write, or both
//    transactions have been accepted in the determination if all transactions
//    are done for a manager.
//  * Fairness: If both reads and writes can start independently of each other,
//    then we may never be able to switch the grant to a new manager. The
//    existing manager might keep starting the other type of transaction and
//    there will always be one in progress.
//  * Performance: There is the possibility of paralleling a read from one
//    manager and a write from another, if the axi device supports concurrent
//    reads and writes.
//
// Subordinates are routed with even addresses to 0 and odd to 1.
//
// TODO: implement out0 read arb and muxes.
// TODO: implement out1 arb and muxes.
//
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
  logic [2:0] wg0_addr;
  logic [2:0] wg0_greq;

  // The grants. Set to CHANNEL_IDLE if no grant is active.
  //
  // wg0_grant contains the index into the granted manager.
  // wg0_resp contains the index into the granted manager for responses
  //
  // Managing these separately allows for pipe lining across managers.
  localparam CHANNEL_IDLE = 2'b11;
  logic [1:0] next_wg0_grant;
  logic [1:0] wg0_grant;
  logic [1:0] wg0_resp;
  logic       wg0_idle;

  // axi handshake status (they go high in the same clock the transaction
  // occurs in, but are also registered)
  logic       wg0_awdone;
  logic       wg0_wdone;
  // verilator lint_off UNOPTFLAT
  logic       wg0_txn_accepted;
  // verilator lint_on UNOPTFLAT
  logic       wg0_txn_completed;

  assign wg0_addr = {
    ~in2_axi_awaddr[0], ~in1_axi_awaddr[0], ~in0_axi_awaddr[0]
  };

  assign wg0_greq = all_axi_awvalid & wg0_addr;
  assign wg0_idle = wg0_grant == CHANNEL_IDLE;

  txn_done wg0_awdone_inst (
      .clk  (axi_clk),
      .reset(~axi_resetn),
      .valid(out0_axi_awvalid),
      .ready(out0_axi_awready),
      .clear(wg0_txn_accepted),
      .done (wg0_awdone)
  );

  txn_done wg0_wdone_inst (
      .clk  (axi_clk),
      .reset(~axi_resetn),
      .valid(out0_axi_wvalid),
      .ready(out0_axi_wready),
      .clear(wg0_txn_accepted),
      .done (wg0_wdone)
  );

  assign wg0_txn_accepted  = wg0_awdone && wg0_wdone;
  assign wg0_txn_completed = out0_axi_bready && out0_axi_bvalid;

  // Masks for blocking current grant holder from requesting again
  localparam [2:0] MASK_IDLE = 3'b111;
  localparam [2:0] MASK_0 = 3'b110;
  localparam [2:0] MASK_1 = 3'b101;
  localparam [2:0] MASK_2 = 3'b011;

  //
  // out0 grant
  //
  always_comb begin
    logic [2:0] masked_greq;
    logic [2:0] mask;

    // mask out the current txn
    masked_greq    = '0;
    next_wg0_grant = wg0_grant;

    if (wg0_txn_accepted || wg0_idle) begin
      // First mask out current requester and check for others
      if (wg0_idle) begin
        mask = MASK_IDLE;
      end else begin
        case (wg0_grant)
          2'd0:    mask = MASK_0;
          2'd1:    mask = MASK_1;
          2'd2:    mask = MASK_2;
          default: mask = MASK_IDLE;
        endcase
      end

      // Apply mask to grant requests
      masked_greq = wg0_greq & mask;

      // Priority encoder for next grant - check other requesters first
      if (masked_greq & 3'b001) begin
        next_wg0_grant = 0;
      end else if (masked_greq & 3'b010) begin
        next_wg0_grant = 1;
      end else if (masked_greq & 3'b100) begin
        next_wg0_grant = 2;
      end else begin
        // If no other requests, keep current requester.
        // This prevents a pipeline bubble from transitioning
        // back through idle before starting the next txn.
        if (!wg0_idle && wg0_greq[wg0_grant]) begin
          next_wg0_grant = wg0_grant;
        end else begin
          next_wg0_grant = CHANNEL_IDLE;
        end
      end
    end
  end

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      wg0_grant <= CHANNEL_IDLE;
    end else begin
      wg0_grant <= next_wg0_grant;
    end
  end

  //
  // out0 AW and W mux
  //
  assign out0_axi_awaddr  = all_axi_awaddr[wg0_grant];
  assign out0_axi_awvalid = all_axi_awvalid[wg0_grant];
  assign out0_axi_wdata   = all_axi_wdata[wg0_grant];
  assign out0_axi_wstrb   = all_axi_wstrb[wg0_grant];
  assign out0_axi_wvalid  = all_axi_wvalid[wg0_grant];

  // out0 A and W ready mux
  always_comb begin
    in0_axi_awready = '0;
    in0_axi_wready  = '0;
    in1_axi_awready = '0;
    in1_axi_wready  = '0;
    in2_axi_awready = '0;
    in2_axi_wready  = '0;

    case (wg0_grant)
      2'd0: begin
        in0_axi_awready = out0_axi_awready;
        in0_axi_wready  = out0_axi_wready;
      end

      2'd1: begin
        in1_axi_awready = out0_axi_awready;
        in1_axi_wready  = out0_axi_wready;
      end

      2'd2: begin
        in2_axi_awready = out0_axi_awready;
        in2_axi_wready  = out0_axi_wready;
      end

      default: begin
      end
    endcase
  end

  logic [2:0] wg0_fifo_w_data;
  logic       wg0_fifo_w_inc;

  logic [2:0] wg0_fifo_r_data;
  logic       wg0_fifo_r_inc;

  logic       wg0_fifo_r_empty;
  // verilator lint_off UNUSEDSIGNAL
  logic       wg0_fifo_w_full;
  // verilator lint_on UNUSEDSIGNAL

  assign wg0_fifo_w_data = wg0_grant;
  assign wg0_fifo_w_inc  = wg0_txn_accepted;
  assign wg0_fifo_r_inc  = wg0_txn_completed;

  assign wg0_resp        = wg0_fifo_r_empty ? CHANNEL_IDLE : wg0_fifo_r_data;

  // I tried to figure out a way to just set the wg0_resp register when
  // txn's are accepted, but I couldn't figure it out. When heavy pipelining
  // and grant ordering was happening, I kept losing track of responses.
  // A fifo clearly works, although, there may be some more optimal way
  // of doing this.
  sync_fifo #(
      .DATA_WIDTH(3),
      .ADDR_SIZE (3)
  ) wg0_resp_fifo (
      .clk    (axi_clk),
      .rst_n  (axi_resetn),
      .w_inc  (wg0_fifo_w_inc),
      .w_data (wg0_fifo_w_data),
      .w_full (wg0_fifo_w_full),
      .r_inc  (wg0_fifo_r_inc),
      .r_data (wg0_fifo_r_data),
      .r_empty(wg0_fifo_r_empty)
  );

  //
  // out0 B mux
  //
  assign out0_axi_bready = all_axi_bready[wg0_resp];

  always_comb begin
    in0_axi_bvalid = '0;
    in1_axi_bvalid = '0;
    in2_axi_bvalid = '0;

    case (wg0_resp)
      2'd0: begin
        in0_axi_bvalid = out0_axi_bvalid;
      end

      2'd1: begin
        in1_axi_bvalid = out0_axi_bvalid;
      end

      2'd2: begin
        in2_axi_bvalid = out0_axi_bvalid;
      end

      default: begin
      end
    endcase
  end

endmodule
// verilator lint_on UNUSEDSIGNAL
// verilator lint_on UNDRIVEN

`endif
