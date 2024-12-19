`ifndef SRAM_CONTROLLER_V
`define SRAM_CONTROLLER_V

`include "directives.sv"

`include "sram_io_ice40.sv"

module sram_controller #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // to/from the caller
    input logic clk,
    input logic reset,

    // initiate a request
    input logic req,

    // the controller/sram is ready to take a request
    output logic ready,

    input  logic                 write_enable,
    input  logic [ADDR_BITS-1:0] addr,
    input  logic [DATA_BITS-1:0] write_data,
    output logic                 write_done,
    output logic [DATA_BITS-1:0] read_data,
    output logic                 read_data_valid,

    // to/from the sram chip
    output logic [ADDR_BITS-1:0] io_addr_bus,
    inout  wire  [DATA_BITS-1:0] io_data_bus,
    output logic                 io_we_n,
    output logic                 io_oe_n,
    output logic                 io_ce_n
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

  //
  // State
  //
  logic active;
  logic writing;

  logic next_active;
  logic next_writing;

  //
  // Next state
  //
  always_comb begin
    if (!active) begin
      next_active  = req;
      next_writing = write_enable;
    end else begin
      next_active  = 1'b0;
      next_writing = 1'b0;
    end
  end

  //
  // State registration
  //
  always_ff @(posedge clk) begin
    if (reset) begin
      active  <= 1'b0;
      writing <= 1'b0;
    end else begin
      active  <= next_active;
      writing <= next_writing;
    end
  end

  //
  // Pad signals
  //
  logic [ADDR_BITS-1:0] pad_addr;
  logic [DATA_BITS-1:0] pad_write_data;
  logic                 pad_write_data_enable;
  logic [DATA_BITS-1:0] pad_read_data;
  logic                 pad_read_data_valid;
  logic                 pad_ce_n;
  logic                 pad_we_n;
  logic                 pad_oe_n;

  sram_io_ice40 #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) u_sram_io_ice40 (
      .clk(clk),

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
  // Addr/data to pad
  //
  always_ff @(posedge clk) begin
    if (next_active) begin
      pad_addr <= addr;
      if (next_writing) begin
        pad_write_data <= write_data;
      end
    end
  end

  //
  // Control signals
  //
  always_ff @(posedge clk) begin
    pad_ce_n              <= 1'b0;
    pad_write_data_enable <= writing || next_writing;
    pad_we_n              <= !next_writing;
    pad_oe_n              <= !(next_active && !next_writing);
  end

  assign read_data       = pad_read_data;
  assign read_data_valid = pad_read_data_valid;
  assign ready           = !active;

  assign write_done      = writing;

endmodule

`endif
