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

// TODO: parameterize the number of managers and subordinates in the modules
// and move them to their own files.
// verilator lint_off DECLFILENAME

//
// common arbiter module for reads and writes
//
module axi_arbiter (
    input logic axi_clk,
    input logic axi_resetn,

    // bitmask of managers requesting a grant
    input logic [2:0] requesting_grant,

    // the request grant is released on tnx_accepted,
    // and the response grant is released on txn_completed
    input logic txn_accepted,
    input logic txn_completed,

    // the active_request and response container the manager granted
    // the respective bus. (The holder of the response grant previosly
    // held the active_request. This enables pipelining.)
    output logic [1:0] active_request,
    output logic [1:0] active_response
);
  localparam CHANNEL_IDLE = 2'b11;

  // Masks for blocking current grant holder from requesting again
  localparam [2:0] MASK_IDLE = 3'b111;
  localparam [2:0] MASK_0 = 3'b110;
  localparam [2:0] MASK_1 = 3'b101;
  localparam [2:0] MASK_2 = 3'b011;

  logic [1:0] next_grant;
  logic       idle;

  assign idle = active_request == CHANNEL_IDLE;

  always_comb begin
    logic [2:0] masked_greq;
    logic [2:0] mask;

    // mask out the current txn
    masked_greq = '0;
    next_grant  = active_request;

    if (txn_accepted || idle) begin
      // First mask out current requester and check for others
      if (idle) begin
        mask = MASK_IDLE;
      end else begin
        case (active_request)
          2'd0:    mask = MASK_0;
          2'd1:    mask = MASK_1;
          2'd2:    mask = MASK_2;
          default: mask = MASK_IDLE;
        endcase
      end

      // Apply mask to grant requests
      masked_greq = requesting_grant & mask;

      // Priority encoder for next grant - check other requesters first
      if (masked_greq & 3'b001) begin
        next_grant = 0;
      end else if (masked_greq & 3'b010) begin
        next_grant = 1;
      end else if (masked_greq & 3'b100) begin
        next_grant = 2;
      end else begin
        // If no other requests, keep current requester.
        // This prevents a pipeline bubble from transitioning
        // back through idle before starting the next txn.
        if (!idle && requesting_grant[active_request]) begin
          next_grant = active_request;
        end else begin
          next_grant = CHANNEL_IDLE;
        end
      end
    end
  end

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      active_request <= CHANNEL_IDLE;
    end else begin
      active_request <= next_grant;
    end
  end

  //
  // fifo for passing the request grant into the response phase
  //
  logic [2:0] fifo_w_data;
  logic       fifo_w_inc;

  logic [2:0] fifo_r_data;
  logic       fifo_r_inc;

  logic       fifo_r_empty;
  // verilator lint_off UNUSEDSIGNAL
  logic       fifo_w_full;
  // verilator lint_on UNUSEDSIGNAL

  assign fifo_w_data     = active_request;
  assign fifo_w_inc      = txn_accepted;
  assign fifo_r_inc      = txn_completed;

  assign active_response = fifo_r_empty ? CHANNEL_IDLE : fifo_r_data;

  sync_fifo #(
      .DATA_WIDTH(3),
      .ADDR_SIZE (3)
  ) wg0_resp_fifo (
      .clk    (axi_clk),
      .rst_n  (axi_resetn),
      .w_inc  (fifo_w_inc),
      .w_data (fifo_w_data),
      .w_full (fifo_w_full),
      .r_inc  (fifo_r_inc),
      .r_data (fifo_r_data),
      .r_empty(fifo_r_empty)
  );
endmodule

module axi_arbitrated_mux #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    // Concatenated manager input ports
    input logic [3:0][AXI_ADDR_WIDTH-1:0] in_axi_awaddr,
    input logic [3:0]                     in_axi_awvalid,
    input logic [3:0][AXI_DATA_WIDTH-1:0] in_axi_wdata,
    input logic [3:0][AXI_STRB_WIDTH-1:0] in_axi_wstrb,
    input logic [3:0]                     in_axi_wvalid,
    input logic [3:0]                     in_axi_bready,
    input logic [3:0][AXI_ADDR_WIDTH-1:0] in_axi_araddr,
    input logic [3:0]                     in_axi_arvalid,
    input logic [3:0]                     in_axi_rready,

    // Concatenated manager output ports
    output logic [2:0]                     in_axi_awready,
    output logic [2:0]                     in_axi_wready,
    output logic [2:0]                     in_axi_bvalid,
    output logic [2:0][               1:0] in_axi_bresp,
    output logic [2:0]                     in_axi_arready,
    output logic [2:0]                     in_axi_rvalid,
    output logic [2:0][AXI_DATA_WIDTH-1:0] in_axi_rdata,
    output logic [2:0][               1:0] in_axi_rresp,

    // Subordinate select
    input logic [2:0] wg_addr,
    input logic [2:0] rg_addr,

    // Subordinate interface
    output logic [AXI_ADDR_WIDTH-1:0] out_axi_awaddr,
    output logic                      out_axi_awvalid,
    input  logic                      out_axi_awready,
    output logic [AXI_DATA_WIDTH-1:0] out_axi_wdata,
    output logic [AXI_STRB_WIDTH-1:0] out_axi_wstrb,
    output logic                      out_axi_wvalid,
    input  logic                      out_axi_wready,
    input  logic [               1:0] out_axi_bresp,
    input  logic                      out_axi_bvalid,
    output logic                      out_axi_bready,
    output logic [AXI_ADDR_WIDTH-1:0] out_axi_araddr,
    output logic                      out_axi_arvalid,
    input  logic                      out_axi_arready,
    input  logic [AXI_DATA_WIDTH-1:0] out_axi_rdata,
    input  logic [               1:0] out_axi_rresp,
    input  logic                      out_axi_rvalid,
    output logic                      out_axi_rready
);
  // Grants
  logic [1:0] wg_grant;
  logic [1:0] wg_resp;
  logic [1:0] rg_grant;
  logic [1:0] rg_resp;

  // Write accepted is used to clear the registered done signals, but is also
  // the result of those signals. Tell the linter that we, hopefully, know what
  // we are doing. This might need to be revisited under icecube2.
  // verilator lint_off UNOPTFLAT
  logic       wg_txn_accepted;
  // verilator lint_on UNOPTFLAT
  //
  logic       wg_txn_completed;
  logic       rg_txn_accepted;
  logic       rg_txn_completed;

  logic       wg_awdone;
  logic       wg_wdone;

  logic [2:0] wg_greq;
  logic [2:0] rg_greq;

  assign wg_greq = in_axi_awvalid[2:0] & wg_addr;
  assign rg_greq = in_axi_arvalid[2:0] & rg_addr;

  txn_done wg_awdone_inst (
      .clk  (axi_clk),
      .reset(~axi_resetn),
      .valid(out_axi_awvalid),
      .ready(out_axi_awready),
      .clear(wg_txn_accepted),
      .done (wg_awdone)
  );

  txn_done wg_wdone_inst (
      .clk  (axi_clk),
      .reset(~axi_resetn),
      .valid(out_axi_wvalid),
      .ready(out_axi_wready),
      .clear(wg_txn_accepted),
      .done (wg_wdone)
  );

  assign wg_txn_accepted  = wg_awdone && wg_wdone;
  assign wg_txn_completed = out_axi_bvalid && out_axi_bready;

  assign rg_txn_accepted  = out_axi_arvalid && out_axi_arready;
  assign rg_txn_completed = out_axi_rvalid && out_axi_rready;

  axi_arbiter wg_arbiter_inst (
      .axi_clk         (axi_clk),
      .axi_resetn      (axi_resetn),
      .requesting_grant(wg_greq),
      .txn_accepted    (wg_txn_accepted),
      .txn_completed   (wg_txn_completed),
      .active_request  (wg_grant),
      .active_response (wg_resp)
  );

  axi_arbiter rg_arbiter_inst (
      .axi_clk         (axi_clk),
      .axi_resetn      (axi_resetn),
      .requesting_grant(rg_greq),
      .txn_accepted    (rg_txn_accepted),
      .txn_completed   (rg_txn_completed),
      .active_request  (rg_grant),
      .active_response (rg_resp)
  );

  assign out_axi_awaddr  = in_axi_awaddr[wg_grant];
  assign out_axi_awvalid = in_axi_awvalid[wg_grant];
  assign out_axi_wdata   = in_axi_wdata[wg_grant];
  assign out_axi_wstrb   = in_axi_wstrb[wg_grant];
  assign out_axi_wvalid  = in_axi_wvalid[wg_grant];
  assign out_axi_bready  = in_axi_bready[wg_resp];
  assign out_axi_araddr  = in_axi_araddr[rg_grant];
  assign out_axi_arvalid = in_axi_arvalid[rg_grant];
  assign out_axi_rready  = in_axi_rready[rg_resp];

  always_comb begin
    in_axi_awready = '0;
    in_axi_wready  = '0;

    if (wg_grant != 2'b11) begin
      in_axi_awready[wg_grant] = out_axi_awready;
      in_axi_wready[wg_grant]  = out_axi_wready;
    end
  end

  always_comb begin
    in_axi_bvalid = '0;
    in_axi_bresp  = '0;

    if (wg_resp != 2'b11) begin
      in_axi_bvalid[wg_resp] = out_axi_bvalid;
      in_axi_bresp[wg_resp]  = out_axi_bresp;
    end
  end

  always_comb begin
    in_axi_arready = '0;

    if (rg_grant != 2'b11) begin
      in_axi_arready[rg_grant] = out_axi_arready;
    end
  end

  always_comb begin
    in_axi_rvalid = '0;
    in_axi_rdata  = '0;
    in_axi_rresp  = '0;

    if (rg_resp != 2'b11) begin
      in_axi_rvalid[rg_resp] = out_axi_rvalid;
      in_axi_rdata[rg_resp]  = out_axi_rdata;
      in_axi_rresp[rg_resp]  = out_axi_rresp;
    end
  end
endmodule

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
  //
  // Concatenate the inputs from the managers
  //
  logic [3:0][AXI_ADDR_WIDTH-1:0] in_axi_awaddr;
  logic [3:0]                     in_axi_awvalid;
  logic [3:0][AXI_DATA_WIDTH-1:0] in_axi_wdata;
  logic [3:0][AXI_STRB_WIDTH-1:0] in_axi_wstrb;
  logic [3:0]                     in_axi_wvalid;
  logic [3:0]                     in_axi_bready;
  logic [3:0][AXI_ADDR_WIDTH-1:0] in_axi_araddr;
  logic [3:0]                     in_axi_arvalid;
  logic [3:0]                     in_axi_rready;

  assign in_axi_awaddr = {
    {AXI_ADDR_WIDTH{1'b0}}, in2_axi_awaddr, in1_axi_awaddr, in0_axi_awaddr
  };
  assign in_axi_awvalid = {
    1'b0, in2_axi_awvalid, in1_axi_awvalid, in0_axi_awvalid
  };
  assign in_axi_wdata = {
    {AXI_DATA_WIDTH{1'b0}}, in2_axi_wdata, in1_axi_wdata, in0_axi_wdata
  };
  assign in_axi_wstrb = {
    {AXI_STRB_WIDTH{1'b0}}, in2_axi_wstrb, in1_axi_wstrb, in0_axi_wstrb
  };
  assign in_axi_wvalid = {1'b0, in2_axi_wvalid, in1_axi_wvalid, in0_axi_wvalid};
  assign in_axi_bready = {1'b0, in2_axi_bready, in1_axi_bready, in0_axi_bready};
  assign in_axi_araddr = {
    {AXI_ADDR_WIDTH{1'b0}}, in2_axi_araddr, in1_axi_araddr, in0_axi_araddr
  };
  assign in_axi_arvalid = {
    1'b0, in2_axi_arvalid, in1_axi_arvalid, in0_axi_arvalid
  };
  assign in_axi_rready = {1'b0, in2_axi_rready, in1_axi_rready, in0_axi_rready};

  //
  // Muxed subordinate output back to the managers
  //
  logic [2:0]                     out0_in_axi_awready;
  logic [2:0]                     out0_in_axi_wready;
  logic [2:0]                     out0_in_axi_bvalid;
  logic [2:0][               1:0] out0_in_axi_bresp;
  logic [2:0]                     out0_in_axi_arready;
  logic [2:0]                     out0_in_axi_rvalid;
  logic [2:0][AXI_DATA_WIDTH-1:0] out0_in_axi_rdata;
  logic [2:0][               1:0] out0_in_axi_rresp;

  logic [2:0]                     out1_in_axi_awready;
  logic [2:0]                     out1_in_axi_wready;
  logic [2:0]                     out1_in_axi_bvalid;
  logic [2:0][               1:0] out1_in_axi_bresp;
  logic [2:0]                     out1_in_axi_arready;
  logic [2:0]                     out1_in_axi_rvalid;
  logic [2:0][AXI_DATA_WIDTH-1:0] out1_in_axi_rdata;
  logic [2:0][               1:0] out1_in_axi_rresp;

  // Connect ready signals back to managers, combining both muxes
  assign in0_axi_awready = out0_in_axi_awready[0] | out1_in_axi_awready[0];
  assign in1_axi_awready = out0_in_axi_awready[1] | out1_in_axi_awready[1];
  assign in2_axi_awready = out0_in_axi_awready[2] | out1_in_axi_awready[2];

  assign in0_axi_wready = out0_in_axi_wready[0] | out1_in_axi_wready[0];
  assign in1_axi_wready = out0_in_axi_wready[1] | out1_in_axi_wready[1];
  assign in2_axi_wready = out0_in_axi_wready[2] | out1_in_axi_wready[2];

  // Response signals back to managers
  assign in0_axi_bvalid = out0_in_axi_bvalid[0] | out1_in_axi_bvalid[0];
  assign in1_axi_bvalid = out0_in_axi_bvalid[1] | out1_in_axi_bvalid[1];
  assign in2_axi_bvalid = out0_in_axi_bvalid[2] | out1_in_axi_bvalid[2];

  assign in0_axi_bresp = out0_in_axi_bresp[0] | out1_in_axi_bresp[0];
  assign in1_axi_bresp = out0_in_axi_bresp[1] | out1_in_axi_bresp[1];
  assign in2_axi_bresp = out0_in_axi_bresp[2] | out1_in_axi_bresp[2];

  assign in0_axi_arready = out0_in_axi_arready[0] | out1_in_axi_arready[0];
  assign in1_axi_arready = out0_in_axi_arready[1] | out1_in_axi_arready[1];
  assign in2_axi_arready = out0_in_axi_arready[2] | out1_in_axi_arready[2];

  assign in0_axi_rvalid = out0_in_axi_rvalid[0] | out1_in_axi_rvalid[0];
  assign in1_axi_rvalid = out0_in_axi_rvalid[1] | out1_in_axi_rvalid[1];
  assign in2_axi_rvalid = out0_in_axi_rvalid[2] | out1_in_axi_rvalid[2];

  // Route read data and responses from the active mux
  assign in0_axi_rdata = (out0_in_axi_rvalid[0] ? out0_in_axi_rdata[0] :
                          out1_in_axi_rdata[0]);
  assign in1_axi_rdata = (out0_in_axi_rvalid[1] ? out0_in_axi_rdata[1] :
                          out1_in_axi_rdata[1]);
  assign in2_axi_rdata = (out0_in_axi_rvalid[2] ? out0_in_axi_rdata[2] :
                          out1_in_axi_rdata[2]);

  assign in0_axi_rresp = (out0_in_axi_rvalid[0] ? out0_in_axi_rresp[0] :
                          out1_in_axi_rresp[0]);
  assign in1_axi_rresp = (out0_in_axi_rvalid[1] ? out0_in_axi_rresp[1] :
                          out1_in_axi_rresp[1]);
  assign in2_axi_rresp = (out0_in_axi_rvalid[2] ? out0_in_axi_rresp[2] :
                          out1_in_axi_rresp[2]);

  //
  // Address routing
  //
  logic [2:0] wg0_addr;
  logic [2:0] rg0_addr;
  logic [2:0] wg1_addr;
  logic [2:0] rg1_addr;

  // even to wg0/rg0
  assign wg0_addr = {
    ~in2_axi_awaddr[0], ~in1_axi_awaddr[0], ~in0_axi_awaddr[0]
  };
  assign rg0_addr = {
    ~in2_axi_araddr[0], ~in1_axi_araddr[0], ~in0_axi_araddr[0]
  };

  // odd to wg1/rg1
  assign wg1_addr = {in2_axi_awaddr[0], in1_axi_awaddr[0], in0_axi_awaddr[0]};
  assign rg1_addr = {in2_axi_araddr[0], in1_axi_araddr[0], in0_axi_araddr[0]};

  // Instantiate mux for subordinate 0 (even addresses)
  axi_arbitrated_mux #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_STRB_WIDTH(AXI_STRB_WIDTH)
  ) sub0_mux (
      .axi_clk        (axi_clk),
      .axi_resetn     (axi_resetn),
      .in_axi_awaddr  (in_axi_awaddr),
      .in_axi_awvalid (in_axi_awvalid),
      .in_axi_wdata   (in_axi_wdata),
      .in_axi_wstrb   (in_axi_wstrb),
      .in_axi_wvalid  (in_axi_wvalid),
      .in_axi_bready  (in_axi_bready),
      .in_axi_araddr  (in_axi_araddr),
      .in_axi_arvalid (in_axi_arvalid),
      .in_axi_rready  (in_axi_rready),
      .wg_addr        (wg0_addr),
      .rg_addr        (rg0_addr),
      .in_axi_awready (out0_in_axi_awready),
      .in_axi_wready  (out0_in_axi_wready),
      .in_axi_bvalid  (out0_in_axi_bvalid),
      .in_axi_bresp   (out0_in_axi_bresp),
      .in_axi_arready (out0_in_axi_arready),
      .in_axi_rvalid  (out0_in_axi_rvalid),
      .in_axi_rdata   (out0_in_axi_rdata),
      .in_axi_rresp   (out0_in_axi_rresp),
      .out_axi_awaddr (out0_axi_awaddr),
      .out_axi_awvalid(out0_axi_awvalid),
      .out_axi_awready(out0_axi_awready),
      .out_axi_wdata  (out0_axi_wdata),
      .out_axi_wstrb  (out0_axi_wstrb),
      .out_axi_wvalid (out0_axi_wvalid),
      .out_axi_wready (out0_axi_wready),
      .out_axi_bresp  (out0_axi_bresp),
      .out_axi_bvalid (out0_axi_bvalid),
      .out_axi_bready (out0_axi_bready),
      .out_axi_araddr (out0_axi_araddr),
      .out_axi_arvalid(out0_axi_arvalid),
      .out_axi_arready(out0_axi_arready),
      .out_axi_rdata  (out0_axi_rdata),
      .out_axi_rresp  (out0_axi_rresp),
      .out_axi_rvalid (out0_axi_rvalid),
      .out_axi_rready (out0_axi_rready)
  );

  // Instantiate mux for subordinate 1 (odd addresses)
  axi_arbitrated_mux #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_STRB_WIDTH(AXI_STRB_WIDTH)
  ) sub1_mux (
      .axi_clk        (axi_clk),
      .axi_resetn     (axi_resetn),
      .in_axi_awaddr  (in_axi_awaddr),
      .in_axi_awvalid (in_axi_awvalid),
      .in_axi_wdata   (in_axi_wdata),
      .in_axi_wstrb   (in_axi_wstrb),
      .in_axi_wvalid  (in_axi_wvalid),
      .in_axi_bready  (in_axi_bready),
      .in_axi_araddr  (in_axi_araddr),
      .in_axi_arvalid (in_axi_arvalid),
      .in_axi_rready  (in_axi_rready),
      .wg_addr        (wg1_addr),
      .rg_addr        (rg1_addr),
      .in_axi_awready (out1_in_axi_awready),
      .in_axi_wready  (out1_in_axi_wready),
      .in_axi_bvalid  (out1_in_axi_bvalid),
      .in_axi_bresp   (out1_in_axi_bresp),
      .in_axi_arready (out1_in_axi_arready),
      .in_axi_rvalid  (out1_in_axi_rvalid),
      .in_axi_rdata   (out1_in_axi_rdata),
      .in_axi_rresp   (out1_in_axi_rresp),
      .out_axi_awaddr (out1_axi_awaddr),
      .out_axi_awvalid(out1_axi_awvalid),
      .out_axi_awready(out1_axi_awready),
      .out_axi_wdata  (out1_axi_wdata),
      .out_axi_wstrb  (out1_axi_wstrb),
      .out_axi_wvalid (out1_axi_wvalid),
      .out_axi_wready (out1_axi_wready),
      .out_axi_bresp  (out1_axi_bresp),
      .out_axi_bvalid (out1_axi_bvalid),
      .out_axi_bready (out1_axi_bready),
      .out_axi_araddr (out1_axi_araddr),
      .out_axi_arvalid(out1_axi_arvalid),
      .out_axi_arready(out1_axi_arready),
      .out_axi_rdata  (out1_axi_rdata),
      .out_axi_rresp  (out1_axi_rresp),
      .out_axi_rvalid (out1_axi_rvalid),
      .out_axi_rready (out1_axi_rready)
  );

endmodule
// verilator lint_on DECLFILENAME

`endif
