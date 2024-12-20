`ifndef SRAM_TESTER_AXI_V
`define SRAM_TESTER_AXI_V

`include "directives.sv"

`include "axi_skidbuf.sv"
`include "axi_sram_controller.sv"
`include "iter.sv"
`include "sram_pattern_generator.sv"
`include "sticky_bit.sv"
`include "sync_fifo.sv"

//
// This module is a mess. It was one of my first, and looking back with some
// experience, it could be so much cleaner.
//

module sram_tester_axi #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // tester signals
    input  logic clk,
    input  logic reset,
    output logic test_done,
    output logic test_pass,

    // debug/output signals
    output logic [          2:0] pattern_state,
    output logic [DATA_BITS-1:0] read_data,
    output logic [DATA_BITS-1:0] expected_data,
    output logic [ADDR_BITS-1:0] iter_addr,

    // sram controller to io pins
    output logic [ADDR_BITS-1:0] sram_io_addr,
    inout  wire  [DATA_BITS-1:0] sram_io_data,
    output logic                 sram_io_we_n,
    output logic                 sram_io_oe_n,
    output logic                 sram_io_ce_n
);
  // AXI-Lite Write Address Channel
  logic [        ADDR_BITS-1:0] axi_awaddr;
  logic                         axi_awvalid;
  logic                         axi_awready;

  // AXI-Lite Write Data Channel
  logic [        DATA_BITS-1:0] axi_wdata;
  logic [((DATA_BITS+7)/8)-1:0] axi_wstrb;
  logic                         axi_wvalid;
  logic                         axi_wready;

  // AXI-Lite Write Response Channel
  logic                         axi_bvalid;
  logic                         axi_bready;
  // verilator lint_off UNUSEDSIGNAL
  logic [                  1:0] axi_bresp;
  // verilator lint_on UNUSEDSIGNAL

  // AXI-Lite Read Address Channel
  logic [        ADDR_BITS-1:0] axi_araddr;
  logic                         axi_arvalid;
  logic                         axi_arready;

  // AXI-Lite Read Data Channel
  logic [        DATA_BITS-1:0] axi_rdata;
  // verilator lint_off UNUSEDSIGNAL
  logic [                  1:0] axi_rresp;
  // verilator lint_on UNUSEDSIGNAL
  logic                         axi_rvalid;
  logic                         axi_rready;

  // sram versions
  logic [        ADDR_BITS-1:0] sram_axi_awaddr;
  logic                         sram_axi_awvalid;
  logic                         sram_axi_awready;
  logic [        DATA_BITS-1:0] sram_axi_wdata;
  logic [((DATA_BITS+7)/8)-1:0] sram_axi_wstrb;
  logic                         sram_axi_wvalid;
  logic                         sram_axi_wready;
  logic [                  1:0] sram_axi_bresp;
  logic                         sram_axi_bvalid;
  logic                         sram_axi_bready;
  logic [        ADDR_BITS-1:0] sram_axi_araddr;
  logic                         sram_axi_arvalid;
  logic                         sram_axi_arready;
  logic [        DATA_BITS-1:0] sram_axi_rdata;
  logic [                  1:0] sram_axi_rresp;
  logic                         sram_axi_rvalid;
  logic                         sram_axi_rready;

  //
  // Address iteration
  //
  logic                         iter_addr_inc;
  logic                         iter_addr_done;

  //
  // Pattern gen signals
  //
  logic                         pattern_reset;
  logic                         pattern_inc;
  logic [        DATA_BITS-1:0] pattern;
  logic                         pattern_done;
  logic [        DATA_BITS-1:0] pattern_custom;

  //
  // Fifo signals
  //
  logic                         fifo_write_inc;
  logic                         fifo_read_inc;
  logic [        DATA_BITS-1:0] fifo_write_data;
  logic [        DATA_BITS-1:0] fifo_read_data;
  // verilator lint_off UNUSEDSIGNAL
  logic                         fifo_empty;
  logic                         fifo_full;
  logic                         fifo_almost_full;
  // verilator lint_on UNUSEDSIGNAL

  assign axi_wstrb = '1;

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(ADDR_BITS),
      .AXI_DATA_WIDTH(DATA_BITS)
  ) ctrl (
      .axi_clk     (clk),
      .axi_resetn  (~reset),
      .axi_awaddr  (sram_axi_awaddr),
      .axi_awvalid (sram_axi_awvalid),
      .axi_awready (sram_axi_awready),
      .axi_wdata   (sram_axi_wdata),
      .axi_wstrb   (sram_axi_wstrb),
      .axi_wvalid  (sram_axi_wvalid),
      .axi_wready  (sram_axi_wready),
      .axi_bresp   (sram_axi_bresp),
      .axi_bvalid  (sram_axi_bvalid),
      .axi_bready  (sram_axi_bready),
      .axi_araddr  (sram_axi_araddr),
      .axi_arvalid (sram_axi_arvalid),
      .axi_arready (sram_axi_arready),
      .axi_rdata   (sram_axi_rdata),
      .axi_rresp   (sram_axi_rresp),
      .axi_rvalid  (sram_axi_rvalid),
      .axi_rready  (sram_axi_rready),
      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  axi_skidbuf #(
      .AXI_ADDR_WIDTH(ADDR_BITS),
      .AXI_DATA_WIDTH(DATA_BITS)
  ) axi_skidbuf_i (
      .axi_clk   (clk),
      .axi_resetn(~reset),

      .s_axi_awaddr (axi_awaddr),
      .s_axi_awvalid(axi_awvalid),
      .s_axi_awready(axi_awready),
      .s_axi_wdata  (axi_wdata),
      .s_axi_wstrb  (axi_wstrb),
      .s_axi_wvalid (axi_wvalid),
      .s_axi_wready (axi_wready),
      .s_axi_bresp  (axi_bresp),
      .s_axi_bvalid (axi_bvalid),
      .s_axi_bready (axi_bready),
      .s_axi_araddr (axi_araddr),
      .s_axi_arvalid(axi_arvalid),
      .s_axi_arready(axi_arready),
      .s_axi_rdata  (axi_rdata),
      .s_axi_rresp  (axi_rresp),
      .s_axi_rvalid (axi_rvalid),
      .s_axi_rready (axi_rready),

      .m_axi_awaddr (sram_axi_awaddr),
      .m_axi_awvalid(sram_axi_awvalid),
      .m_axi_awready(sram_axi_awready),
      .m_axi_wdata  (sram_axi_wdata),
      .m_axi_wstrb  (sram_axi_wstrb),
      .m_axi_wvalid (sram_axi_wvalid),
      .m_axi_wready (sram_axi_wready),
      .m_axi_bresp  (sram_axi_bresp),
      .m_axi_bvalid (sram_axi_bvalid),
      .m_axi_bready (sram_axi_bready),
      .m_axi_araddr (sram_axi_araddr),
      .m_axi_arvalid(sram_axi_arvalid),
      .m_axi_arready(sram_axi_arready),
      .m_axi_rdata  (sram_axi_rdata),
      .m_axi_rresp  (sram_axi_rresp),
      .m_axi_rvalid (sram_axi_rvalid),
      .m_axi_rready (sram_axi_rready)
  );

  // preserves the semantics of the previous kind of iter
  iter #(
      .WIDTH(ADDR_BITS)
  ) addr_gen (
      .clk     (clk),
      .init    (reset || (iter_addr_done && iter_addr_inc)),
      .init_val('0),
      .max_val ('1),
      .inc     (iter_addr_inc),
      .val     (iter_addr),
      .last    (iter_addr_done)
  );

  sram_pattern_generator #(
      .DATA_BITS(DATA_BITS)
  ) pattern_gen (
      .clk    (clk),
      .reset  (pattern_reset),
      .inc    (pattern_inc),
      .custom (pattern_custom),
      .pattern(pattern),
      .done   (pattern_done),
      .state  (pattern_state)
  );

  //
  // Push the expected data through a fifo and read it out to validate.
  // We do this because we don't know how many cycles a read may take
  // and don't know how long to delay the expected pattern data.
  sync_fifo #(
      .ADDR_SIZE (3),
      .DATA_WIDTH(DATA_BITS)
  ) expected_fifo (
      .clk          (clk),
      .rst_n        (~reset),
      .w_inc        (fifo_write_inc),
      .w_data       (fifo_write_data),
      .w_full       (fifo_full),
      .w_almost_full(fifo_almost_full),
      .r_inc        (fifo_read_inc),
      .r_data       (fifo_read_data),
      .r_empty      (fifo_empty)
  );

  //
  // State machine
  //
  // TODO: cleanup the states and remove the need for NEXT_PATTERN,
  // it's partially needed because of the weirdness with the iter,
  // which really should have a last signal instead of done.
  localparam [2:0] INIT = 3'b000;
  localparam [2:0] WRITING = 3'b001;
  localparam [2:0] READING = 3'b100;
  localparam [2:0] NEXT_PATTERN = 3'b101;
  localparam [2:0] DONE = 3'b110;
  localparam [2:0] HALT = 3'b111;

  logic [2:0] state;
  logic [2:0] next_state;

  logic [3:0] writes_outstanding;
  logic [3:0] reads_outstanding;

  //
  // next_state
  //
  always_comb begin
    next_state  = state;
    write_start = 1'b0;
    read_start  = 1'b0;

    case (state)
      INIT: begin
        next_state  = WRITING;
        write_start = 1'b1;
      end

      WRITING: begin
        if (!writes_done) begin
          write_start = write_accepted && !last_write;
        end else begin
          next_state = READING;
          read_start = 1'b1;
        end
      end

      READING: begin
        if (!reads_done) begin
          read_start = read_accepted && !last_read;
        end else begin
          if (pattern_done) begin
            next_state = DONE;
          end else begin
            next_state = NEXT_PATTERN;
          end
        end
      end

      NEXT_PATTERN: begin
        next_state  = WRITING;
        write_start = 1'b1;
      end

      DONE: begin
        next_state  = WRITING;
        write_start = 1'b1;
      end

      HALT: begin
      end

      default: begin
      end
    endcase
  end

  //
  // state registration
  //
  always_ff @(posedge clk) begin
    if (reset) begin
      state <= INIT;
    end else begin
      if (test_pass) begin
        state <= next_state;
      end else begin
        state <= HALT;
      end
    end
  end

  //
  // writes outstanding
  //
  always_ff @(posedge clk) begin
    if (reset) begin
      writes_outstanding <= 0;
    end else begin
      if (write_start && !write_completed) begin
        writes_outstanding <= writes_outstanding + 1;
      end else if (!write_start && write_completed) begin
        writes_outstanding <= writes_outstanding - 1;
      end
    end
  end

  //
  // reads outstanding
  //
  always_ff @(posedge clk) begin
    if (reset) begin
      reads_outstanding <= 0;
    end else begin
      if (read_start && !read_completed) begin
        reads_outstanding <= reads_outstanding + 1;
      end else if (!read_start && read_completed) begin
        reads_outstanding <= reads_outstanding - 1;
      end
    end
  end

  //
  // writing
  //
  logic write_start;

  logic write_addr_accepted;
  logic write_data_accepted;
  logic write_accepted;
  logic write_completed;


  sticky_bit sticky_awdone (
      .clk  (clk),
      .reset(reset),
      .in   (axi_awvalid && axi_awready),
      .out  (write_addr_accepted),
      .clear(write_accepted)
  );

  sticky_bit sticky_wdone (
      .clk  (clk),
      .reset(reset),
      .in   (axi_wvalid && axi_wready),
      .out  (write_data_accepted),
      .clear(write_accepted)
  );

  logic last_write;
  logic writes_done;

  assign write_accepted  = (write_addr_accepted && write_data_accepted);
  assign write_completed = (axi_bvalid && axi_bready);
  assign writes_done     = (writes_outstanding == 0 && last_write);

  always_ff @(posedge clk) begin
    if (reset) begin
      axi_awaddr  <= 0;
      axi_awvalid <= 1'b0;
      axi_wdata   <= '0;
      axi_wvalid  <= 1'b0;
      axi_bready  <= 1'b0;
    end else begin
      if (write_start) begin
        axi_awaddr  <= iter_addr;
        axi_awvalid <= 1'b1;
        axi_wdata   <= pattern;
        axi_wvalid  <= 1'b1;
        axi_bready  <= 1'b1;
      end else begin
        if (axi_awready && axi_awvalid) begin
          axi_awvalid <= 1'b0;
        end

        if (axi_wready && axi_wvalid) begin
          axi_wvalid <= 1'b0;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      last_write <= 1'b0;
    end else begin
      if (write_start) begin
        last_write <= iter_addr_done;
      end
    end
  end

  //
  // reading
  //
  logic read_start;

  logic read_accepted;
  assign read_accepted = axi_arready & axi_arvalid;

  logic read_completed;
  assign read_completed = axi_rready & axi_rvalid;

  logic last_read;

  logic reads_done;
  assign reads_done = (reads_outstanding == 0 & last_read);

  //
  // Start read
  //
  always_ff @(posedge clk) begin
    if (reset) begin
      axi_araddr     <= 0;
      axi_arvalid    <= 1'b0;
      axi_rready     <= 1'b0;

      last_read      <= 1'b0;
      fifo_write_inc <= 1'b0;
    end else begin
      fifo_write_inc <= 1'b0;

      // We're always ready for a response
      axi_rready     <= 1'b1;

      if (read_start) begin
        axi_araddr      <= iter_addr;
        axi_arvalid     <= 1'b1;

        last_read       <= iter_addr_done;

        fifo_write_inc  <= 1'b1;
        fifo_write_data <= pattern;
      end else begin
        if (read_accepted) begin
          axi_arvalid <= 1'b0;
        end
      end
    end
  end

  //
  // read response
  //
  logic read_data_done;
  assign read_data_done = (axi_rready & axi_rvalid);
  assign fifo_read_inc  = read_data_done;

  assign read_data      = axi_rdata;
  assign expected_data  = fifo_read_data;

  always_ff @(posedge clk) begin
    if (reset) begin
      test_pass <= 1'b1;
    end else begin
      if (read_data_done) begin
        test_pass <= expected_data == read_data;
      end
    end
  end

  //
  // Addr and pattern looping
  //
  assign iter_addr_inc  = (write_start | read_start);
  assign pattern_reset  = (state == DONE | reset);
  assign pattern_inc    = (next_state == NEXT_PATTERN);
  assign pattern_custom = iter_addr[DATA_BITS-1:0];
  assign test_done      = (state == DONE);

endmodule

`endif
