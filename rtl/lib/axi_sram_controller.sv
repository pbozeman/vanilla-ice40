`ifndef AXI_SRAM_CONTROLLER_V
`define AXI_SRAM_CONTROLLER_V

`include "directives.sv"

`include "sram_io_ice40.sv"

// FIXME: consider addressing the following:
//
// SPEC MISMATCH: This differs from how axi addresses are supposed to work.
// I misunderstood the addr scheme and thought the addresses were for words of
// size DATA_WIDTH. If this module is instantiated with a DATA_WIDTH of 16,
// addr 0 will return word 0 (bytes 1 and 0 from the sram on the data bus),
// and addr 1 will word 1 (bytes 2 and 3 from the sram on the data bus.)

// Note: wstrb is ignored as the boards with the sram chips
// I use have the ub and lb pins hard logicd to enable.
//
// TODO: come back and implement wstrb, and/or consider setting
// an error in the resp if they are used.
module axi_sram_controller #(
    parameter  integer AXI_ADDR_WIDTH = 20,
    parameter  integer AXI_DATA_WIDTH = 16,
    localparam         AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8
) (
    input logic axi_clk,
    input logic axi_resetn,

    input  logic [AXI_ADDR_WIDTH-1:0] axi_awaddr,
    input  logic                      axi_awvalid,
    output logic                      axi_awready,
    input  logic [AXI_DATA_WIDTH-1:0] axi_wdata,
    // verilator lint_off UNUSEDSIGNAL
    input  logic [AXI_STRB_WIDTH-1:0] axi_wstrb,
    // verilator lint_on UNUSEDSIGNAL
    input  logic                      axi_wvalid,
    output logic                      axi_wready,
    output logic [               1:0] axi_bresp,
    output logic                      axi_bvalid,
    input  logic                      axi_bready,

    input  logic [AXI_ADDR_WIDTH-1:0] axi_araddr,
    input  logic                      axi_arvalid,
    output logic                      axi_arready,
    output logic [AXI_DATA_WIDTH-1:0] axi_rdata,
    output logic [               1:0] axi_rresp,
    output logic                      axi_rvalid,
    input  logic                      axi_rready,

    output logic [AXI_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire  [AXI_DATA_WIDTH-1:0] sram_io_data,
    output logic                      sram_io_we_n,
    output logic                      sram_io_oe_n,
    output logic                      sram_io_ce_n
);
  // Reads and writes happen over 2 clock cycles.
  //
  // For writes, we wait half a clock (5 ns) for signals to settle, then
  // pulse we_n on a negative clock edge for a full 10ns. We don't update
  // data or addresses until we_n has been high for another 5ns.
  // The order is:
  //   .... we_n is disabled
  //   first_leading_edge: set addr and data lines.
  //   first_falling_edge: set we_n
  //   second_leading_edge: hold/idle
  //   second_falling_edge: release we_n
  //   .... and we_n is disabled for half a clock before we start over
  //
  // Reads are similar in that oe_n happens on the negative clock
  // edge. Because output is disabled half a clock before the next op,
  // we don't have to wait between a read and a write as the sram goes
  // high-z after 4ns, and we won't be writing for at least 5.

  //
  // state signals
  //
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] READING = 2'b01;
  localparam [1:0] WRITING = 2'b10;

  logic [               1:0] state;
  logic [               1:0] next_state;

  logic                      read_start;
  logic                      write_start;
  logic                      write_start_p1;
  logic                      sram_ready;
  logic                      pri_read;

  //
  // the ice40 pads
  //
  logic [AXI_ADDR_WIDTH-1:0] pad_addr;
  logic [AXI_DATA_WIDTH-1:0] pad_write_data;
  logic                      pad_write_data_enable;
  logic [AXI_DATA_WIDTH-1:0] pad_read_data;
  logic                      pad_read_data_valid;
  logic                      pad_ce_n;
  logic                      pad_we_n;
  logic                      pad_oe_n;

  assign pad_ce_n = 1'b0;

  sram_io_ice40 #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) u_sram_io_ice40 (
      .clk(axi_clk),

      .pad_addr             (pad_addr),
      .pad_write_data       (pad_write_data),
      .pad_write_data_enable(pad_write_data_enable),
      .pad_read_data        (pad_read_data),
      .pad_read_data_valid  (pad_read_data_valid),
      .pad_ce_n             (pad_ce_n),
      .pad_we_n             (pad_we_n),
      .pad_oe_n             (pad_oe_n),

      .io_addr_bus(sram_io_addr),
      .io_data_bus(sram_io_data),
      .io_we_n    (sram_io_we_n),
      .io_oe_n    (sram_io_oe_n),
      .io_ce_n    (sram_io_ce_n)
  );

  //
  // state machine
  //

  always_comb begin
    next_state  = state;
    read_start  = 1'b0;
    write_start = 1'b0;

    case (state)
      IDLE: begin
        if (sram_ready) begin
          if (pri_read) begin
            if (axi_arvalid) begin
              next_state = READING;
              read_start = 1'b1;
            end else if (axi_awvalid && axi_wvalid) begin
              next_state  = WRITING;
              write_start = 1'b1;
            end
          end else begin
            if (axi_awvalid && axi_wvalid) begin
              next_state  = WRITING;
              write_start = 1'b1;
            end else if (axi_arvalid) begin
              next_state = READING;
              read_start = 1'b1;
            end
          end
        end
      end

      READING: begin
        if (axi_rready) begin
          next_state = IDLE;
          if (sram_ready) begin
            if (axi_awvalid && axi_wvalid) begin
              next_state = WRITING;
              read_start = 1'b1;
            end else if (axi_arvalid) begin
              next_state = READING;
              read_start = 1'b1;
            end
          end
        end
      end

      WRITING: begin
        if (axi_bready) begin
          next_state = IDLE;
          if (sram_ready) begin
            if (axi_arvalid) begin
              next_state = READING;
              read_start = 1'b1;
            end else if (axi_awvalid && axi_wvalid) begin
              next_state  = WRITING;
              write_start = 1'b1;
            end
          end
        end
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

  always_ff @(posedge axi_clk) begin
    sram_ready <= !write_start && !read_start;
  end

  always_ff @(posedge axi_clk) begin
    if (write_start) begin
      pri_read <= 1'b1;
    end else if (read_start) begin
      pri_read <= 1'b0;
    end
  end

  //
  // Reads
  //
  assign axi_arready = read_start;

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      pad_oe_n <= 1'b1;
    end else begin
      pad_oe_n <= !read_start;
    end
  end

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      axi_rvalid <= 1'b0;
      axi_rdata  <= '0;
      axi_rresp  <= '0;
    end else begin
      // We should be checking to see if axi_rvalid is already high and doing
      // something skid buffer like if so.
      // All current callers will be ok with this, but it should be fixed.
      if (pad_read_data_valid) begin
        axi_rvalid <= 1'b1;
        axi_rdata  <= pad_read_data;
      end else if (axi_rvalid && axi_rready) begin
        axi_rvalid <= 1'b0;
      end
    end
  end

  //
  // Writes
  //
  always_ff @(posedge axi_clk) begin
    // used for holding the pad active, and detecting when done
    write_start_p1 <= write_start;
  end

  assign axi_awready = write_start;
  assign axi_wready  = write_start;

  always_ff @(posedge axi_clk) begin
    if (write_start) begin
      pad_write_data <= axi_wdata;
    end
  end

  always_ff @(posedge axi_clk) begin
    pad_write_data_enable <= (write_start || write_start_p1);
  end

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      pad_we_n <= 1'b1;
    end else begin
      pad_we_n <= !write_start;
    end
  end

  always_ff @(posedge axi_clk) begin
    if (~axi_resetn) begin
      axi_bvalid <= '0;
      axi_bresp  <= '0;
    end else begin
      if (write_start) begin
        axi_bvalid <= 1'b1;
      end else if (axi_bvalid && axi_bready) begin
        axi_bvalid <= 1'b0;
      end
    end
  end

  //
  // Addr (shared with read/write)
  //
  always_ff @(posedge axi_clk) begin
    if (read_start) begin
      pad_addr <= axi_araddr;
    end else if (write_start) begin
      pad_addr <= axi_awaddr;
    end
  end

endmodule

`endif
