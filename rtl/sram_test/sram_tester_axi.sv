`ifndef SRAM_TESTER_AXI_V
`define SRAM_TESTER_AXI_V

`include "directives.sv"

`include "axi_sram_controller.sv"
`include "fifo.sv"
`include "iter.sv"
`include "sram_pattern_generator.sv"

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
    output logic [DATA_BITS-1:0] prev_read_data,
    output logic [DATA_BITS-1:0] prev_expected_data,
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
  // verilator lint_off UNUSEDSIGNAL
  logic [                  1:0] axi_bresp;
  logic                         axi_bvalid;
  // verilator lint_on UNUSEDSIGNAL
  logic                         axi_bready;

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
  logic                         fifo_write_en;
  logic                         fifo_read_en;
  logic [        DATA_BITS-1:0] fifo_write_data;
  logic [        DATA_BITS-1:0] fifo_read_data;
  // verilator lint_off UNUSEDSIGNAL
  logic                         fifo_empty;
  logic                         fifo_full;
  // verilator lint_on UNUSEDSIGNAL

  assign axi_wstrb = 2'b11;

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(ADDR_BITS),
      .AXI_DATA_WIDTH(DATA_BITS)
  ) ctrl (
      .axi_clk     (clk),
      .axi_resetn  (~reset),
      .axi_awaddr  (axi_awaddr),
      .axi_awvalid (axi_awvalid),
      .axi_awready (axi_awready),
      .axi_wdata   (axi_wdata),
      .axi_wstrb   (axi_wstrb),
      .axi_wvalid  (axi_wvalid),
      .axi_wready  (axi_wready),
      .axi_bresp   (axi_bresp),
      .axi_bvalid  (axi_bvalid),
      .axi_bready  (axi_bready),
      .axi_araddr  (axi_araddr),
      .axi_arvalid (axi_arvalid),
      .axi_arready (axi_arready),
      .axi_rdata   (axi_rdata),
      .axi_rresp   (axi_rresp),
      .axi_rvalid  (axi_rvalid),
      .axi_rready  (axi_rready),
      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  iter #(
      .MAX_VALUE((1 << ADDR_BITS) - 1)
  ) addr_gen (
      .clk  (clk),
      .reset(reset),
      .inc  (iter_addr_inc),
      .val  (iter_addr),
      .done (iter_addr_done)
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
  fifo #(
      .DEPTH     (8),
      .DATA_WIDTH(DATA_BITS)
  ) expected_fifo (
      .clk       (clk),
      .reset     (reset),
      .write_en  (fifo_write_en),
      .read_en   (fifo_read_en),
      .write_data(fifo_write_data),
      .read_data (fifo_read_data),
      .empty     (fifo_empty),
      .full      (fifo_full)
  );

  //
  // State machine
  //
  localparam [2:0] START = 3'b000;
  localparam [2:0] WRITE = 3'b001;
  localparam [2:0] WRITE_WAIT = 3'b010;
  localparam [2:0] READ = 3'b100;
  localparam [2:0] READ_WAIT = 3'b101;
  localparam [2:0] DONE = 3'b110;
  localparam [2:0] HALT = 3'b111;

  logic [2:0] state;
  logic [2:0] next_state;

  //
  // next_state
  //
  always_comb begin
    next_state  = state;
    write_start = 1'b0;
    read_start  = 1'b0;

    case (state)
      START: begin
        next_state  = WRITE;
        write_start = 1'b1;
      end

      WRITE: begin
        next_state = WRITE_WAIT;
      end

      WRITE_WAIT: begin
        if (write_accepted) begin
          if (writes_done) begin
            next_state = READ;
            read_start = 1'b1;
          end else begin
            next_state  = WRITE;
            write_start = 1'b1;
          end
        end
      end

      READ: begin
        next_state = READ_WAIT;
      end

      READ_WAIT: begin
        if (read_accepted) begin
          if (reads_done) begin
            if (pattern_done) begin
              next_state = DONE;
            end else begin
              next_state  = WRITE;
              write_start = 1'b1;
            end
          end else begin
            next_state = READ;
            read_start = 1'b1;
          end
        end
      end

      DONE: begin
        next_state  = WRITE;
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
      state <= START;
    end else begin
      if (test_pass) begin
        state <= next_state;
      end else begin
        state <= HALT;
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

  logic last_write;
  logic writes_done;

  assign write_accepted = (write_addr_accepted & write_data_accepted);
  assign writes_done    = (write_accepted & last_write);

  always_ff @(posedge clk) begin
    if (reset) begin
      axi_awaddr          <= 0;
      axi_awvalid         <= 1'b1;
      axi_wdata           <= 1'b0;
      axi_wvalid          <= 1'b0;
      axi_bready          <= 1'b0;

      write_addr_accepted <= 1'b0;
      write_data_accepted <= 1'b0;
    end else begin
      if (write_start) begin
        axi_awaddr          <= iter_addr;
        axi_awvalid         <= 1'b1;
        axi_wdata           <= pattern;
        axi_wvalid          <= 1'b1;
        axi_bready          <= 1'b1;

        write_addr_accepted <= 1'b0;
        write_data_accepted <= 1'b0;
      end else begin
        if (axi_awready && axi_awvalid) begin
          write_addr_accepted <= 1'b1;
          axi_awvalid         <= 1'b0;
        end

        if (axi_wready && axi_wvalid) begin
          write_data_accepted <= 1'b1;
          axi_wvalid          <= 1'b0;
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

  logic last_read;

  logic reads_done;
  assign reads_done = (read_accepted & last_read);

  //
  // Start read
  //
  always_ff @(posedge clk) begin
    if (reset) begin
      axi_araddr    <= 0;
      axi_arvalid   <= 1'b0;
      axi_rready    <= 1'b0;

      last_read     <= 1'b0;
      fifo_write_en <= 1'b0;
    end else begin
      fifo_write_en <= 1'b0;

      // We're always ready for a response
      axi_rready    <= 1'b1;

      if (read_start) begin
        axi_araddr      <= iter_addr;
        axi_arvalid     <= 1'b1;

        last_read       <= iter_addr_done;

        fifo_write_en   <= 1'b1;
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
  logic validate;
  logic read_data_done;

  assign read_data_done = (axi_rready & axi_rvalid);

  always_ff @(posedge clk) begin
    if (reset) begin
      validate <= 1'b0;
    end else begin
      validate <= 1'b0;

      if (read_data_done) begin
        validate       <= 1'b1;
        prev_read_data <= axi_rdata;
      end
    end
  end

  assign fifo_read_en       = read_data_done;
  assign prev_expected_data = fifo_read_data;

  always_ff @(posedge clk) begin
    if (reset) begin
      test_pass <= 1'b1;
    end else begin
      if (validate) begin
        if (prev_expected_data != prev_read_data) begin
          test_pass <= 1'b0;
        end
      end
    end
  end

  //
  // Addr and pattern looping
  //
  assign iter_addr_inc  = (write_start | read_start);
  assign pattern_reset  = (state == DONE | reset);
  assign pattern_inc    = (state == READ_WAIT & iter_addr_done);
  assign pattern_custom = iter_addr;
  assign test_done      = (state == DONE);

endmodule

`endif