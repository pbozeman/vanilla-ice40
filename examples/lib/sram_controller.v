`ifndef SRAM_CONTROLLER_V
`define SRAM_CONTROLLER_V

`include "directives.v"

`include "sram_io_ice40.v"

module sram_controller #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // to/from the caller
    input wire clk,
    input wire reset,

    // initiate a request
    input wire req,

    // the controller/sram is ready to take a request
    output wire ready,

    input  wire                 write_enable,
    input  wire [ADDR_BITS-1:0] addr,
    input  wire [DATA_BITS-1:0] write_data,
    output wire                 write_done,
    output wire [DATA_BITS-1:0] read_data,
    output wire                 read_data_valid,

    // to/from the sram chip
    output wire [ADDR_BITS-1:0] io_addr_bus,
    inout  wire [DATA_BITS-1:0] io_data_bus,
    output wire                 io_we_n,
    output wire                 io_oe_n,
    output wire                 io_ce_n
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
  localparam IDLE = 2'd0;
  localparam READING = 2'd1;
  localparam WRITING = 2'd2;

  //
  // State
  //
  reg [2:0] state = 0;
  reg [2:0] next_state = 0;
  reg       ready_reg;

  //
  // Next state
  //
  always @(*) begin
    next_state = state;

    case (state)
      IDLE: begin
        if (req) begin
          if (!write_enable) begin
            next_state = READING;
          end else begin
            next_state = WRITING;
          end
        end
      end

      READING: begin
        next_state = IDLE;
      end

      WRITING: begin
        next_state = IDLE;
      end

      default: begin
        next_state = state;
      end
    endcase
  end

  //
  // State registration
  //
  always @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  //
  // Pad signals
  //
  reg  [ADDR_BITS-1:0] pad_addr;
  reg  [DATA_BITS-1:0] pad_write_data;
  reg                  pad_write_data_enable;
  wire [DATA_BITS-1:0] pad_read_data;
  wire                 pad_read_data_valid;
  reg                  pad_ce_n;
  reg                  pad_we_n;
  reg                  pad_oe_n;

  sram_io_ice40 #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) u_sram_io_ice40 (
      .clk  (clk),
      .reset(reset),

      .pad_addr             (pad_addr),
      .pad_write_data       (pad_write_data),
      .pad_write_data_enable(pad_write_data_enable),
      .pad_read_data        (pad_read_data),
      .pad_read_data_valid  (pad_read_data_valid),
      .pad_ce_n             (pad_ce_n),
      .pad_we_n             (pad_we_n),
      .pad_oe_n             (pad_oe_n),

      .io_addr_bus(io_addr_bus),
      .io_data_bus(io_data_bus),
      .io_we_n    (io_we_n),
      .io_oe_n    (io_oe_n),
      .io_ce_n    (io_ce_n)
  );

  //
  // Ready
  //
  always @(posedge clk) begin
    if (reset) begin
      ready_reg <= 1;
    end else begin
      ready_reg <= (next_state == IDLE);
    end
  end

  //
  // Addr/data to pad
  //
  always @(posedge clk) begin
    if (next_state != IDLE) begin
      pad_addr <= addr;
      if (write_enable) begin
        pad_write_data <= write_data;
      end
    end
  end

  //
  // Control signals
  //
  always @(posedge clk) begin
    pad_ce_n              <= 1'b0;
    pad_write_data_enable <= (next_state == WRITING || state == WRITING);
    pad_we_n              <= !(next_state == WRITING);
    pad_oe_n              <= !(next_state == READING);
  end

  assign read_data       = pad_read_data;
  assign read_data_valid = pad_read_data_valid;
  assign ready           = ready_reg;

  assign write_done      = (state == WRITING);

endmodule

`endif
