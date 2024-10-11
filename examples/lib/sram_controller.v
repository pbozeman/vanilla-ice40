`ifndef SRAM_CONTROLLER_V
`define SRAM_CONTROLLER_V

`include "directives.v"

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
    output reg  [DATA_BITS-1:0] read_data,

    // to/from the sram chip
    output reg  [ADDR_BITS-1:0] io_addr_bus,
    inout  wire [DATA_BITS-1:0] io_data_bus,
    output reg                  io_we_n,
    output reg                  io_oe_n,
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

  reg [2:0] state = 0;

  reg [2:0] next_state;
  reg next_oe_n;
  reg next_we_n;

  reg ready_reg;

  reg [DATA_BITS-1:0] write_data_reg = 0;

  // For now, we can just leave the chip always enabled. We control
  // the chip with oe_n and we_n instead. Reconsider this if we want to
  // put the chip into idle/low power mode.
  assign io_ce_n = 1'b0;

  assign io_data_bus = (next_state == WRITING || state == WRITING) ? write_data : {DATA_BITS{1'bz}};

  always @(*) begin
    next_state = state;
    next_oe_n  = 1'b1;
    next_we_n  = 1'b1;
    ready_reg  = 1'b1;

    case (state)
      IDLE: begin
        if (req) begin
          ready_reg = 1'b0;
          if (!write_enable) begin
            next_state = READING;
            next_oe_n  = 1'b0;
          end else begin
            next_state = WRITING;
            next_we_n  = 1'b0;
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

  always @(*) begin
    io_addr_bus = addr;
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  always @(negedge clk) begin
    if (reset) begin
      io_oe_n <= 1'b1;
      io_we_n <= 1'b1;
    end else begin
      if (!io_oe_n) begin
        read_data <= io_data_bus;
      end

      io_we_n <= next_we_n;
      io_oe_n <= next_oe_n;
    end
  end

  assign ready = ready_reg;

endmodule

`endif
