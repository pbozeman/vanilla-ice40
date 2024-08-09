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
    output wire [DATA_BITS-1:0] read_data,

    // to/from the sram chip
    output reg  [ADDR_BITS-1:0] addr_bus,
    inout  wire [DATA_BITS-1:0] data_bus_io,
    output reg                  we_n,
    output wire                 oe_n,
    output wire                 ce_n
);

  // We are fully in spec for writes with a 100mhz clock since they
  // happen over 2 clock cycles. Reads happen in 1 cycle, so may be out of
  // spec at 100mhz, but it's right on the edge and seems to work.
  //
  // For writes, we wait half a clock (5 ns) for signals to settle, then
  // pulse we_n on a negative clock edge for a full 10ns. We don't update
  // data or addresses until we_n has been high for another 5ns.
  // The order is:
  //   .... we_n is disabled
  //   first_leading_edge: set addr and data lines.
  //   first_falling_edge: set we_n
  //   second_leading_edge: hold
  //   second_falling_edge: release we_n
  //   .... and we_n is disabled for half a clock before we start over
  //
  // Reads might be violating the sram specs. While we hold for a full
  // clock, if we are using a 100MHZ clock, this will be right at the 10ns
  // limit. We could be violating timing by a fraction of a nanosecond due
  // to uneven propagation delays, etc. This implementation does not
  // violate timing if the clock is less than 100mhz, e.g. when used
  // with svga pixel clocks.
  //
  // If higher clocks are needed, then add an extra read hold state and
  // then use 2 sram in an interleaved/pipelined fashion.
  //
  // When switching from read to write, we have to wait 1 clock
  // in the READ_TO_WRITE state because the data sheet says it takes
  // 4ns for the sram to go to high-z (thzoe). We don't want to drive the
  // data bus with our write during this time period. Doing so can cause a spike
  // in current which might exceed the maximum current ratings for the output
  // drivers of both devices. Repeated occurrences of such conditions can
  // eventually lead to physical damage to the output drivers of the FPGA or
  // the SRAM, potentially shortening the lifespan of the devices.
  //
  // The chip goes directly to the read state, so the we clock is necessary
  // even on the first use. This could be avoided with an initial IDLE state
  // where oe was not active, but this implementation goes for consistency
  // of use of the write_enable signal.
  //
  localparam IDLE = 3'd0;
  localparam READING = 3'd1;
  localparam READ_TO_WRITE = 3'd2;
  localparam WRITING = 3'd3;
  localparam WRITE_HOLD = 3'd4;

  reg [2:0] state = 0;
  reg [DATA_BITS-1:0] write_data_reg = 0;
  wire bus_active;

  // For now, we can just leave the chip always enabled. We control
  // the chip with oe_n and we_n instead. Reconsider this if we want to
  // put the chip into idle/low power mode.
  assign ce_n = 1'b0;

  assign oe_n = (state != READING);

  // It is tempting to use oe_n to determine we can put data on the bus,
  // but, we need to go through the READ_TO_WRITE transition to allow the
  // chip to release the bus. (see the timing comment at the top of the
  // module)
  assign bus_active = (state == WRITING || state == WRITE_HOLD);
  assign data_bus_io = bus_active ? write_data_reg : {DATA_BITS{1'bz}};

  assign read_data = ~oe_n ? data_bus_io : {DATA_BITS{1'bx}};

  // all states can take a request, except for the double state write
  assign ready = (state != WRITING);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      addr_bus <= addr;
      write_data_reg <= write_data;

      case (state)
        IDLE: state <= ~req ? IDLE : write_enable ? WRITING : READING;
        READING: state <= ~req ? IDLE : write_enable ? READ_TO_WRITE : READING;
        READ_TO_WRITE: state <= WRITING;
        WRITING: state <= WRITE_HOLD;
        WRITE_HOLD: state <= ~req ? IDLE : write_enable ? WRITING : READING;
        default: state <= state;
      endcase
    end
  end

  always @(negedge clk) begin
    we_n <= ~(state == WRITING);
  end

endmodule

`endif
