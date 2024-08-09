`ifndef SRAM_MODEL_V
`define SRAM_MODEL_V

`include "directives.v"

module sram_model #(
    parameter integer ADDR_BITS = 10,
    parameter integer DATA_BITS = 8,
    parameter integer INJECT_ERROR = 0,

    // timings (in ns)
    //
    // Note: tAA should really be 10 to match the real hw.
    // However 10 pushes right up on simulation clock and the
    // harder memory tests fail. The real 10ns chip seems to work
    // with the sram_controller at 100Mhz. It is unclear to me
    // if I'm running the chip beyond spec, but if so,
    // it's right on the very edge of being out of compliance.
    parameter real tAA  = 9,    // Address Access Time
    parameter real tOHA = 2.5,  // Output Hold Time
    parameter real tDOE = 6,    // OE# Access Time
    parameter real tAW  = 8,    // Address Setup Time to Write End

    parameter integer BAD_DATA = 1'bx
) (
    input wire we_n,
    input wire oe_n,
    input wire ce_n,
    input wire [ADDR_BITS-1:0] addr,
    inout wire [DATA_BITS-1:0] data_io
);

  // memory
  reg [DATA_BITS-1:0] sram[0:(1 << ADDR_BITS)-1];

  // data read from bus
  wire [DATA_BITS-1:0] data_in;

  // data written to bus, possibly tri-state if output not enabled
  wire output_active;
  reg [DATA_BITS-1:0] data_out;


  // Previous data for output hold time
  reg [DATA_BITS-1:0] prev_data;

  // Time of last address change
  real last_addr_change;

  // Time of last OE# falling edge
  real last_oe_fall;

  // Data signals
  assign output_active = !ce_n && !oe_n;
  assign data_in = data_io;
  assign data_io = output_active ? data_out : {DATA_BITS{1'bz}};

  // Delayed address update and data handling
  always @(addr) begin
    prev_data = data_out;
    last_addr_change = $realtime;
  end

  // Track OE# falling edge
  always @(negedge oe_n) begin
    data_out = {DATA_BITS{1'bz}};
    last_oe_fall = $realtime;
  end

  always begin
    if (output_active) begin
      if ($realtime - last_oe_fall < tDOE) begin
        data_out = {DATA_BITS{1'bz}};
      end else if ($realtime - last_addr_change < tOHA) begin
        data_out = prev_data;
      end else if ($realtime - last_addr_change < tAA) begin
        data_out = {DATA_BITS{BAD_DATA}};
      end else begin
        data_out = sram[addr];
      end
    end

    #1;
  end

  // Write operation
  reg write_enable = 0;

  always @(we_n, ce_n, addr) begin
    if (!we_n && !ce_n) begin
      #(tAW) write_enable = 1;
    end else begin
      // FIXME: this might need a delay too
      write_enable = 0;
    end
  end

  // We do immediate assignment so that our timings are explicit.
  // (Note: tAW to write_enabled is delayed.)
  //
  // However, if we try to ensure all paths in this block
  // assign to sram[addr], thus avoiding the latch warning,
  // we create a circular dependency that iverilog can't optimize
  // and the compile at >16 bits of addr space takes forever.
  // Hence, we allow latch creation below.
  //
  // verilator lint_off LATCH
  always @(*) begin
    if (write_enable) begin
      if (INJECT_ERROR && addr == {DATA_BITS{1'b1}}) begin
        sram[addr] = {DATA_BITS{1'b1}};
      end else if (!we_n) begin
        sram[addr] = data_in;
      end
    end
  end
  // verilator lint_on LATCH

endmodule

`endif
