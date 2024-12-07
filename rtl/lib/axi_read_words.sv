`ifndef AXI_READ_WORDS_V
`define AXI_READ_WORDS_V

`include "directives.sv"

`include "iter.sv"
`include "sync_fifo.sv"

// Like axi_stripe_reader, this takes a parameter like arlen, but instead
// it uses arlenw. This is because I misunderstood axi when first implementing
// it, and the addrs are actually for words of DATA_WIDTH size. This should be
// fixed, but in the mean time, let's make it clear that arlen isn't bytes.
module axi_read_words #(
    parameter STRIDE           = 2,
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

    // Subordinate interface
    output logic [AXI_ADDR_WIDTH-1:0] out_axi_araddr,
    output logic                      out_axi_arvalid,
    input  logic                      out_axi_arready,
    input  logic [AXI_DATA_WIDTH-1:0] out_axi_rdata,
    // verilator lint_off UNUSEDSIGNAL
    input  logic [               1:0] out_axi_rresp,
    // verilator lint_on UNUSEDSIGNAL
    input  logic                      out_axi_rvalid,
    output logic                      out_axi_rready
);
  // state machine
  //
  // It might be possible to remove a cycle of latency from INIT_BURST
  // but the addr management is tricky to not avoid a circular dependency
  // due to addr_last. For the initial use case of this, this optimization
  // is not needed.
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] INIT_BURST = 2'b01;
  localparam [1:0] READING_BEATS = 2'b10;
  localparam [1:0] FINISH_BURST = 2'b11;

  logic [               1:0] state;
  logic [               1:0] next_state;

  // addr of the word we are reading
  logic [AXI_ADDR_WIDTH-1:0] addr;
  logic                      addr_init;
  logic [AXI_ADDR_WIDTH-1:0] addr_init_val;
  logic [AXI_ADDR_WIDTH-1:0] addr_max_val;
  logic                      addr_inc;
  logic                      addr_last;

  // start/accept/done signals
  logic                      burst_start;
  logic                      beat_read_start;
  logic                      beat_read_accepted;
  logic                      beat_read_done;
  logic                      beat_read_last;

  // pre read addr metadata (really only the last bit)
  logic                      meta_fifo_w_almost_full;

  assign beat_read_accepted = out_axi_arvalid && out_axi_arready;
  assign beat_read_done     = out_axi_rvalid && out_axi_rready;

  //
  // State machine
  //
  always_comb begin
    next_state      = state;
    burst_start     = 1'b0;
    beat_read_start = 1'b0;

    case (state)
      IDLE: begin
        if (in_axi_arvalid) begin
          burst_start = 1'b1;
          next_state  = INIT_BURST;
        end
      end

      INIT_BURST: begin
        beat_read_start = 1'b1;
        next_state      = READING_BEATS;
      end

      READING_BEATS: begin
        if (beat_read_accepted) begin
          if (!addr_last) begin
            beat_read_start = !(addr_last || meta_fifo_w_almost_full ||
                                res_fifo_w_almost_full);
          end else begin
            next_state = FINISH_BURST;
          end
        end
      end

      FINISH_BURST: begin
        if (beat_read_accepted && beat_read_last) begin
          next_state = IDLE;
        end
      end

      default: begin
      end
    endcase
  end

  // state reg
  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  // burst start/end
  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      in_axi_arready <= 1'b0;
    end else begin
      if (beat_read_accepted) begin
        in_axi_arready <= 1'b0;
      end

      if (beat_read_done) begin
        in_axi_arready <= 1'b1;
      end
    end
  end

  //
  // Addr index management
  //
  assign addr_init = burst_start;
  assign addr_init_val = in_axi_araddr;
  assign addr_max_val = (in_axi_araddr +
                         (STRIDE * AXI_ADDR_WIDTH'(in_axi_arlenw)));
  assign addr_inc = beat_read_start;

  iter #(
      .WIDTH  (AXI_ADDR_WIDTH),
      .INC_VAL(STRIDE)
  ) addr_iter (
      .clk     (axi_clk),
      .init    (addr_init),
      .init_val(addr_init_val),
      .max_val (addr_max_val),
      .inc     (addr_inc),
      .val     (addr),
      .last    (addr_last)
  );

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      out_axi_araddr  <= '0;
      out_axi_arvalid <= 1'b0;
      out_axi_rready  <= 1'b1;
    end else begin
      if (beat_read_start) begin
        out_axi_araddr  <= addr;
        out_axi_arvalid <= 1'b1;
      end else begin
        if (beat_read_accepted) begin
          out_axi_arvalid <= 1'b0;
        end
      end
    end
  end

  sync_fifo #(
      .DATA_WIDTH     (1),
      .ADDR_SIZE      (3),
      .ALMOST_FULL_BUF(2)
  ) meta_fifo (
      .clk          (axi_clk),
      .rst_n        (axi_resetn),
      .w_inc        (beat_read_start),
      .w_data       (addr_last),
      .w_full       (),
      .w_almost_full(meta_fifo_w_almost_full),
      .r_inc        (beat_read_done),
      .r_data       (beat_read_last),
      .r_empty      ()
  );

  logic [AXI_DATA_WIDTH:0] res_fifo_w_data;
  logic                    res_fifo_w_inc;
  logic                    res_fifo_w_almost_full;
  logic                    res_fifo_r_inc;
  logic [AXI_DATA_WIDTH:0] res_fifo_r_data;
  logic                    res_fifo_r_empty;

  sync_fifo #(
      .DATA_WIDTH     (1 + AXI_DATA_WIDTH),
      .ADDR_SIZE      (3),
      .ALMOST_FULL_BUF(4)
  ) res_fifo (
      .clk          (axi_clk),
      .rst_n        (axi_resetn),
      .w_inc        (res_fifo_w_inc),
      .w_data       (res_fifo_w_data),
      .w_full       (),
      .w_almost_full(res_fifo_w_almost_full),
      .r_inc        (res_fifo_r_inc),
      .r_data       (res_fifo_r_data),
      .r_empty      (res_fifo_r_empty)
  );

  // send responses back to the caller
  logic res_valid;
  assign res_valid       = beat_read_done || !res_fifo_r_empty;

  // if in_axi_rvalid is still set, but the caller isn't ready,
  // we need to buffer the result
  assign res_fifo_w_inc  = beat_read_done && in_axi_rvalid && !in_axi_rready;
  assign res_fifo_w_data = {beat_read_last, out_axi_rdata};
  assign res_fifo_r_inc  = in_axi_rvalid && in_axi_rready && res_fifo_r_empty;

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      in_axi_rvalid <= 1'b0;
    end else begin
      if (res_valid && (!in_axi_rvalid || in_axi_rready)) begin
        in_axi_rvalid <= 1'b1;
        in_axi_rresp  <= '0;
        if (res_fifo_r_empty) begin
          in_axi_rdata <= out_axi_rdata;
          in_axi_rlast <= beat_read_last;
        end else begin
          {in_axi_rlast, in_axi_rdata} <= res_fifo_r_data;
        end
      end else begin
        if (in_axi_rvalid || in_axi_rready) begin
          in_axi_rvalid <= 1'b0;
        end
      end
    end
  end

endmodule

`endif
