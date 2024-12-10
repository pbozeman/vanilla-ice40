`ifndef AXI_STRIPE_READER_V
`define AXI_STRIPE_READER_V

`include "directives.sv"

`include "axi_readn.sv"
`include "iter.sv"

// This module reads from multiple subordinates that have data striped across
// them. It takes a parameter like arlen, but instead it uses arlenw. This is
// because I misunderstood axi when first implementing it, and mistakenly
// thought the addrs were for words of DATA_WIDTH size. This should be fixed,
// but in the mean time, let's make it clear that arlen isn't bytes.
//
// Per the axi spec, arlen is a 0 based count, so 0 is 1 transfer, 1 is 2,
// etc. alrenw for this module is also 0 based.
//
// While the instantiating module sees a single axi interface, this module
// is prefetching the next data while the first set is being processed.
//
// Also, this is a tiny extension to what are otherwise axi-lite modules,
// not full axi.
//
// For now, in_axi_arlenw must be divisible by NUM_S. This isn't caught,
// and this will just break if not the case.
module axi_stripe_reader #(
    parameter NUM_S            = 2,
    parameter AXI_ADDR_WIDTH   = 20,
    parameter AXI_DATA_WIDTH   = 16,
    parameter AXI_ARLENW_WIDTH = 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    input  logic [  AXI_ADDR_WIDTH-1:0] in_axi_araddr,
    input  logic [AXI_ARLENW_WIDTH-1:0] in_axi_arlenw,
    input  logic                        in_axi_arvalid,
    output logic                        in_axi_arready,
    output logic [  AXI_DATA_WIDTH-1:0] in_axi_rdata,
    output logic [                 1:0] in_axi_rresp,
    output logic                        in_axi_rvalid,
    output logic                        in_axi_rlast,
    input  logic                        in_axi_rready,

    // Subordinate interfaces
    output logic [NUM_S-1:0][AXI_ADDR_WIDTH-1:0] out_axi_araddr,
    output logic [NUM_S-1:0]                     out_axi_arvalid,
    input  logic [NUM_S-1:0]                     out_axi_arready,
    input  logic [NUM_S-1:0][AXI_DATA_WIDTH-1:0] out_axi_rdata,
    input  logic [NUM_S-1:0][               1:0] out_axi_rresp,
    input  logic [NUM_S-1:0]                     out_axi_rvalid,
    output logic [NUM_S-1:0]                     out_axi_rready
);
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] INIT_BURST = 2'b01;
  localparam [1:0] READING_BEATS = 2'b10;
  localparam [1:0] COMPLETE = 2'b11;

  logic [      1:0]                       state;
  logic [      1:0]                       next_state;

  logic                                   burst_start;

  logic [NUM_S-1:0][  AXI_ADDR_WIDTH-1:0] strip_axi_araddr;
  logic [NUM_S-1:0][AXI_ARLENW_WIDTH-1:0] strip_axi_arlenw;
  logic [NUM_S-1:0]                       strip_axi_arvalid;
  logic [NUM_S-1:0]                       strip_axi_arready;
  logic [NUM_S-1:0][  AXI_DATA_WIDTH-1:0] strip_axi_rdata;
  logic [NUM_S-1:0][                 1:0] strip_axi_rresp;
  logic [NUM_S-1:0]                       strip_axi_rvalid;
  logic [NUM_S-1:0]                       strip_axi_rlast;
  logic [NUM_S-1:0]                       strip_axi_rready;

  for (genvar i = 0; i < NUM_S; i++) begin : gen_rw
    axi_readn #(
        .STRIDE          (NUM_S),
        .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH  (AXI_DATA_WIDTH),
        .AXI_ARLENW_WIDTH(AXI_ARLENW_WIDTH)
    ) axi_readn_i (
        .axi_clk   (axi_clk),
        .axi_resetn(axi_resetn),

        .in_axi_araddr (strip_axi_araddr[i]),
        .in_axi_arlenw (strip_axi_arlenw[i]),
        .in_axi_arvalid(strip_axi_arvalid[i]),
        .in_axi_arready(strip_axi_arready[i]),
        .in_axi_rdata  (strip_axi_rdata[i]),
        .in_axi_rresp  (strip_axi_rresp[i]),
        .in_axi_rvalid (strip_axi_rvalid[i]),
        .in_axi_rlast  (strip_axi_rlast[i]),
        .in_axi_rready (strip_axi_rready[i]),

        .out_axi_araddr (out_axi_araddr[i]),
        .out_axi_arvalid(out_axi_arvalid[i]),
        .out_axi_arready(out_axi_arready[i]),
        .out_axi_rdata  (out_axi_rdata[i]),
        .out_axi_rresp  (out_axi_rresp[i]),
        .out_axi_rvalid (out_axi_rvalid[i]),
        .out_axi_rready (out_axi_rready[i])
    );
  end

  //
  // strip_idx to rotate through the strips and send them back in sequence
  // to the caller.
  //
  localparam IDX_BITS = $clog2(NUM_S);
  logic [IDX_BITS-1:0] strip_idx;
  logic                strip_idx_init;
  logic                strip_idx_inc;
  logic                strip_idx_last;

  assign strip_idx_init = burst_start || strip_idx_last;
  assign strip_idx_inc  = in_axi_rvalid && in_axi_rready;

  iter #(
      .WIDTH  (IDX_BITS),
      .INC_VAL(1)
  ) iter_strip_idx (
      .clk     (axi_clk),
      .init    (strip_idx_init),
      .init_val('0),
      .max_val (IDX_BITS'(NUM_S - 1)),
      .inc     (strip_idx_inc),
      .val     (strip_idx),
      .last    (strip_idx_last)
  );

  //
  // state machine
  //
  always_comb begin
    next_state  = state;
    burst_start = 1'b0;

    case (state)
      IDLE: begin
        if (in_axi_arvalid) begin
          next_state  = INIT_BURST;
          burst_start = 1'b1;
        end
      end

      INIT_BURST: begin
        next_state = READING_BEATS;
      end

      READING_BEATS: begin
        if (strip_idx_last && strip_axi_rlast[strip_idx]) begin
          next_state = COMPLETE;
        end
      end

      COMPLETE: begin
        next_state = IDLE;
      end

      default: begin
      end
    endcase
  end

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  //
  // strip burst request start signals
  //
  for (genvar i = 0; i < NUM_S; i++) begin : gen_rw_start
    always_ff @(posedge axi_clk) begin
      if (~axi_resetn) begin
        strip_axi_arvalid[i] <= 1'b0;
      end else begin
        if (burst_start) begin
          strip_axi_araddr[i]  <= in_axi_araddr + i;
          strip_axi_arvalid[i] <= 1'b1;
          strip_axi_arlenw[i]  <= (in_axi_arlenw / NUM_S);
        end

        if (strip_axi_arvalid[i] && strip_axi_arready[i]) begin
          strip_axi_arvalid[i] <= 1'b0;
        end
      end
    end
  end

  //
  // strip beat signals back to caller
  //
  always_comb begin
    in_axi_rvalid = state == READING_BEATS ? strip_axi_rvalid[strip_idx] : 1'b0;
    in_axi_rdata = state == READING_BEATS ? strip_axi_rdata[strip_idx] : '0;
    in_axi_rresp = state == READING_BEATS ? strip_axi_rresp[strip_idx] : '0;
  end

  //
  // caller to active strip
  //
  always_comb begin
    strip_axi_rready            = '0;
    strip_axi_rready[strip_idx] = in_axi_rready;
  end

  //
  // burst signals back to the caller
  //
  assign in_axi_rlast   = state == COMPLETE;
  assign in_axi_arready = state == COMPLETE;

endmodule

`endif
