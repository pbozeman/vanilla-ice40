`ifndef AXI_STRIPE_INTERCONNECT_V
`define AXI_STRIPE_INTERCONNECT_V

`include "directives.sv"

`include "axi_arbiter.sv"

module axi_stripe_interconnect #(
    parameter  NUM_M          = 2,
    parameter  NUM_S          = 2,
    parameter  AXI_ADDR_WIDTH = 20,
    parameter  AXI_DATA_WIDTH = 16,
    localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    // AXI-Lite Input for the managers using this module
    input  logic [NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_awaddr,
    input  logic [NUM_M-1:0]                     in_axi_awvalid,
    output logic [NUM_M-1:0]                     in_axi_awready,
    input  logic [NUM_M-1:0][AXI_DATA_WIDTH-1:0] in_axi_wdata,
    input  logic [NUM_M-1:0][AXI_STRB_WIDTH-1:0] in_axi_wstrb,
    input  logic [NUM_M-1:0]                     in_axi_wvalid,
    output logic [NUM_M-1:0]                     in_axi_wready,
    output logic [NUM_M-1:0][               1:0] in_axi_bresp,
    output logic [NUM_M-1:0]                     in_axi_bvalid,
    input  logic [NUM_M-1:0]                     in_axi_bready,
    input  logic [NUM_M-1:0][AXI_ADDR_WIDTH-1:0] in_axi_araddr,
    input  logic [NUM_M-1:0]                     in_axi_arvalid,
    output logic [NUM_M-1:0]                     in_axi_arready,
    output logic [NUM_M-1:0][AXI_DATA_WIDTH-1:0] in_axi_rdata,
    output logic [NUM_M-1:0][               1:0] in_axi_rresp,
    output logic [NUM_M-1:0]                     in_axi_rvalid,
    input  logic [NUM_M-1:0]                     in_axi_rready,

    // Subordinate interfaces
    output logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] out_axi_awaddr,
    output logic [NUM_S-1:0]                     out_axi_awvalid,
    input  logic [NUM_S-1:0]                     out_axi_awready,
    output logic [NUM_S-1:0][AXI_DATA_WIDTH-1:0] out_axi_wdata,
    output logic [NUM_S-1:0][AXI_STRB_WIDTH-1:0] out_axi_wstrb,
    output logic [NUM_S-1:0]                     out_axi_wvalid,
    input  logic [NUM_S-1:0]                     out_axi_wready,
    input  logic [NUM_S-1:0][               1:0] out_axi_bresp,
    input  logic [NUM_S-1:0]                     out_axi_bvalid,
    output logic [NUM_S-1:0]                     out_axi_bready,
    output logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] out_axi_araddr,
    output logic [NUM_S-1:0]                     out_axi_arvalid,
    input  logic [NUM_S-1:0]                     out_axi_arready,
    input  logic [NUM_S-1:0][AXI_DATA_WIDTH-1:0] out_axi_rdata,
    input  logic [NUM_S-1:0][               1:0] out_axi_rresp,
    input  logic [NUM_S-1:0]                     out_axi_rvalid,
    output logic [NUM_S-1:0]                     out_axi_rready
);
  localparam G_BITS = $clog2(NUM_M + 1);
  localparam SEL_BITS = $clog2(NUM_S);

  logic [NUM_S-1:0][G_BITS-1:0] rg_req;
  logic [NUM_S-1:0][G_BITS-1:0] rg_resp;
  logic [NUM_S-1:0][G_BITS-1:0] wg_req;
  logic [NUM_S-1:0][G_BITS-1:0] wg_resp;

  for (genvar i = 0; i < NUM_S; i++) begin : gen_arb
    axi_arbiter #(
        .NUM_M         (NUM_M),
        .SEL_BITS      (SEL_BITS),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
    ) axi_arb_mux_i (
        .a_sel  (SEL_BITS'(i)),
        .rg_req (rg_req[i]),
        .rg_resp(rg_resp[i]),
        .wg_req (wg_req[i]),
        .wg_resp(wg_resp[i]),
        .*
    );
  end

  // Two versions for comparison. Will settle on one at the end when it's
  // clear that all the bugs are worked out.
`ifndef USE_SECOND_VERSION
  // Muxing
  //
  // The comb version:
  //
  // LTP: 42
  //
  // Number of wires:                250
  // Number of wire bits:            911
  // Number of public wires:         250
  // Number of public wire bits:     911
  // Number of ports:                 36
  // Number of port bits:            354
  // Number of memories:               0
  // Number of memory bits:            0
  // Number of processes:              0
  // Number of cells:                367
  //   $scopeinfo                     14
  //   SB_DFFE                        16
  //   SB_DFFESR                      24
  //   SB_DFFESS                       4
  //   SB_DFFSR                        4
  //   SB_LUT4                       305
  //
  // The array muxing version:
  //
  // LTP: 40
  //
  // Number of wires:                265
  // Number of wire bits:           1163
  // Number of public wires:         265
  // Number of public wire bits:    1163
  // Number of ports:                 36
  // Number of port bits:            354
  // Number of memories:               0
  // Number of memory bits:            0
  // Number of processes:              0
  // Number of cells:                371
  //   $scopeinfo                     14
  //   SB_DFFE                        16
  //   SB_DFFESR                      24
  //   SB_DFFESS                       4
  //   SB_DFFSR                        4
  //   SB_LUT4                       309
  //

  //
  // Manager to Subordinate (M->S)
  //

  // Write address channel
  always_comb begin
    for (int s = 0; s < NUM_S; s++) begin
      out_axi_awaddr[s]  = '0;
      out_axi_awvalid[s] = '0;

      for (int m = 0; m < NUM_M; m++) begin
        if (wg_req[s] == G_BITS'(m)) begin
          out_axi_awaddr[s]  = in_axi_awaddr[m];
          out_axi_awvalid[s] = in_axi_awvalid[m];
        end
      end
    end
  end

  // Write data channel
  always_comb begin
    for (int s = 0; s < NUM_S; s++) begin
      out_axi_wdata[s]  = '0;
      out_axi_wstrb[s]  = '0;
      out_axi_wvalid[s] = '0;

      for (int m = 0; m < NUM_M; m++) begin
        if (wg_req[s] == G_BITS'(m)) begin
          out_axi_wdata[s]  = in_axi_wdata[m];
          out_axi_wstrb[s]  = in_axi_wstrb[m];
          out_axi_wvalid[s] = in_axi_wvalid[m];
        end
      end
    end
  end

  // Write response channel
  always_comb begin
    for (int s = 0; s < NUM_S; s++) begin
      out_axi_bready[s] = '0;

      for (int m = 0; m < NUM_M; m++) begin
        if (wg_resp[s] == G_BITS'(m)) begin
          out_axi_bready[s] = in_axi_bready[m];
        end
      end
    end
  end

  // Read address channel
  always_comb begin
    for (int s = 0; s < NUM_S; s++) begin
      out_axi_araddr[s]  = '0;
      out_axi_arvalid[s] = '0;

      for (int m = 0; m < NUM_M; m++) begin
        if (rg_req[s] == G_BITS'(m)) begin
          out_axi_araddr[s]  = in_axi_araddr[m];
          out_axi_arvalid[s] = in_axi_arvalid[m];
        end
      end
    end
  end

  // Read data channel
  always_comb begin
    for (int s = 0; s < NUM_S; s++) begin
      out_axi_rready[s] = '0;

      for (int m = 0; m < NUM_M; m++) begin
        if (rg_resp[s] == G_BITS'(m)) begin
          out_axi_rready[s] = in_axi_rready[m];
        end
      end
    end
  end

  //
  // Subordinate to Manager (S->M)
  //

  // Write channel request
  always_comb begin
    for (int m = 0; m < NUM_M; m++) begin
      in_axi_awready[m] = '0;
      in_axi_wready[m]  = '0;

      for (int s = 0; s < NUM_S; s++) begin
        if (wg_req[s] == G_BITS'(m)) begin
          in_axi_awready[m] = out_axi_awready[s];
          in_axi_wready[m]  = out_axi_wready[s];
        end
      end
    end
  end

  // Write channel responses
  always_comb begin
    for (int m = 0; m < NUM_M; m++) begin
      in_axi_bresp[m]  = '0;
      in_axi_bvalid[m] = '0;

      for (int s = 0; s < NUM_S; s++) begin
        if (wg_resp[s] == G_BITS'(m)) begin
          in_axi_bresp[m]  = out_axi_bresp[s];
          in_axi_bvalid[m] = out_axi_bvalid[s];
        end
      end
    end
  end

  // Read channel request
  always_comb begin
    for (int m = 0; m < NUM_M; m++) begin
      in_axi_arready[m] = '0;

      for (int s = 0; s < NUM_S; s++) begin
        if (rg_req[s] == G_BITS'(m)) begin
          in_axi_arready[m] = out_axi_arready[s];
        end
      end
    end
  end

  // Read channel responses
  always_comb begin
    for (int m = 0; m < NUM_M; m++) begin
      in_axi_rdata[m]  = '0;
      in_axi_rresp[m]  = '0;
      in_axi_rvalid[m] = '0;

      for (int s = 0; s < NUM_S; s++) begin
        if (rg_resp[s] == G_BITS'(m)) begin
          in_axi_rdata[m]  = out_axi_rdata[s];
          in_axi_rresp[m]  = out_axi_rresp[s];
          in_axi_rvalid[m] = out_axi_rvalid[s];
        end
      end
    end
  end

`else

  // Arrays for muxing M->S (including default case at NUM_M index)
  logic [NUM_M:0][AXI_ADDR_WIDTH-1:0] awaddr_array;
  logic [NUM_M:0]                     awvalid_array;
  logic [NUM_M:0][AXI_DATA_WIDTH-1:0] wdata_array;
  logic [NUM_M:0][AXI_STRB_WIDTH-1:0] wstrb_array;
  logic [NUM_M:0]                     wvalid_array;
  logic [NUM_M:0]                     bready_array;
  logic [NUM_M:0][AXI_ADDR_WIDTH-1:0] araddr_array;
  logic [NUM_M:0]                     arvalid_array;
  logic [NUM_M:0]                     rready_array;

  // Arrays for muxing S->M (including default case at NUM_S index)
  logic [NUM_S:0]                     awready_array;
  logic [NUM_S:0]                     wready_array;
  logic [NUM_S:0][               1:0] bresp_array;
  logic [NUM_S:0]                     bvalid_array;
  logic [NUM_S:0]                     arready_array;
  logic [NUM_S:0][AXI_DATA_WIDTH-1:0] rdata_array;
  logic [NUM_S:0][               1:0] rresp_array;
  logic [NUM_S:0]                     rvalid_array;

  // Fill M->S arrays
  always_comb begin
    // Default values at NUM_M index
    awaddr_array[NUM_M]  = '0;
    awvalid_array[NUM_M] = '0;
    wdata_array[NUM_M]   = '0;
    wstrb_array[NUM_M]   = '0;
    wvalid_array[NUM_M]  = '0;
    bready_array[NUM_M]  = '0;
    araddr_array[NUM_M]  = '0;
    arvalid_array[NUM_M] = '0;
    rready_array[NUM_M]  = '0;

    // Fill arrays with manager inputs
    for (int m = 0; m < NUM_M; m++) begin
      awaddr_array[m]  = in_axi_awaddr[m];
      awvalid_array[m] = in_axi_awvalid[m];
      wdata_array[m]   = in_axi_wdata[m];
      wstrb_array[m]   = in_axi_wstrb[m];
      wvalid_array[m]  = in_axi_wvalid[m];
      bready_array[m]  = in_axi_bready[m];
      araddr_array[m]  = in_axi_araddr[m];
      arvalid_array[m] = in_axi_arvalid[m];
      rready_array[m]  = in_axi_rready[m];
    end
  end

  // Fill S->M arrays
  always_comb begin
    // Default values at NUM_S index
    awready_array[NUM_S] = '0;
    wready_array[NUM_S]  = '0;
    bresp_array[NUM_S]   = '0;
    bvalid_array[NUM_S]  = '0;
    arready_array[NUM_S] = '0;
    rdata_array[NUM_S]   = '0;
    rresp_array[NUM_S]   = '0;
    rvalid_array[NUM_S]  = '0;

    // Fill arrays with subordinate inputs
    for (int s = 0; s < NUM_S; s++) begin
      awready_array[s] = out_axi_awready[s];
      wready_array[s]  = out_axi_wready[s];
      bresp_array[s]   = out_axi_bresp[s];
      bvalid_array[s]  = out_axi_bvalid[s];
      arready_array[s] = out_axi_arready[s];
      rdata_array[s]   = out_axi_rdata[s];
      rresp_array[s]   = out_axi_rresp[s];
      rvalid_array[s]  = out_axi_rvalid[s];
    end
  end

  // Direct mux M->S outputs based on grant
  always_comb begin
    for (int s = 0; s < NUM_S; s++) begin
      out_axi_awaddr[s]  = awaddr_array[wg_req[s]];
      out_axi_awvalid[s] = awvalid_array[wg_req[s]];
      out_axi_wdata[s]   = wdata_array[wg_resp[s]];
      out_axi_wstrb[s]   = wstrb_array[wg_resp[s]];
      out_axi_wvalid[s]  = wvalid_array[wg_resp[s]];
      out_axi_bready[s]  = bready_array[wg_resp[s]];
      out_axi_araddr[s]  = araddr_array[rg_req[s]];
      out_axi_arvalid[s] = arvalid_array[rg_req[s]];
      out_axi_rready[s]  = rready_array[rg_resp[s]];
    end
  end

  // Direct mux S->M outputs based on grant
  always_comb begin
    for (int m = 0; m < NUM_M; m++) begin
      // For each manager, we need to find if any subordinate has granted it
      // Default all signals to '0
      in_axi_awready[m] = '0;
      in_axi_wready[m]  = '0;
      in_axi_bresp[m]   = '0;
      in_axi_bvalid[m]  = '0;
      in_axi_arready[m] = '0;
      in_axi_rdata[m]   = '0;
      in_axi_rresp[m]   = '0;
      in_axi_rvalid[m]  = '0;

      // Check each subordinate to see if it granted this manager
      for (int s = 0; s < NUM_S; s++) begin
        if (wg_req[s] == G_BITS'(m)) begin
          in_axi_awready[m] = awready_array[s];
          in_axi_wready[m]  = wready_array[s];
        end
        if (wg_resp[s] == G_BITS'(m)) begin
          in_axi_bresp[m]  = bresp_array[s];
          in_axi_bvalid[m] = bvalid_array[s];
        end
        if (rg_req[s] == G_BITS'(m)) begin
          in_axi_arready[m] = arready_array[s];
        end
        if (rg_resp[s] == G_BITS'(m)) begin
          in_axi_rdata[m]  = rdata_array[s];
          in_axi_rresp[m]  = rresp_array[s];
          in_axi_rvalid[m] = rvalid_array[s];
        end
      end
    end
  end
`endif

endmodule

`endif
