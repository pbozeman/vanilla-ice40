// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module sram_model #(
    parameter integer ADDR_BITS = 9,
    parameter integer DATA_BITS = 8,

    // timings (in ns)
    parameter real tAA  = 10,   // Address Access Time
    parameter real tOHA = 2.5,  // Output Hold Time
    parameter real tDOE = 6,    // OE# Access Time
    parameter real tAW  = 8,    // Address Setup Time to Write End

    parameter integer BAD_DATA = 1'bx
) (
    input wire we_n_i,
    input wire oe_n_i,
    input wire ce_n_i,
    input wire [ADDR_BITS-1:0] addr_i,
    inout wire [DATA_BITS-1:0] data_io
);

  // memory
  // verilator lint_off UNOPTFLAT
  reg [DATA_BITS-1:0] sram[0:(2**ADDR_BITS)-1];
  // verilator lint_on UNOPTFLAT

  // data read from bus
  wire [DATA_BITS-1:0] data_in;

  // data written to bus, possibly tri-state if output not enabled
  reg output_active;
  reg [DATA_BITS-1:0] data_out;


  // Previous data for output hold time
  reg [DATA_BITS-1:0] prev_data;

  // Time of last address change
  real last_addr_change;

  // Time of last OE# falling edge
  real last_oe_fall;

  // Data signals
  assign data_in = data_io;
  assign data_io = output_active ? data_out : {DATA_BITS{1'bz}};

  // Delayed address update and data handling
  always @(addr_i) begin
    prev_data = sram[addr_i];
    last_addr_change = $realtime;
    #(tAA - tOHA) data_out = sram[addr_i];
  end

  // Track OE# falling edge
  always @(negedge oe_n_i) begin
    last_oe_fall = $realtime;
  end

  // Control output_active signal and read operation
  always @(*) begin
    output_active = !ce_n_i && !oe_n_i;
    if (output_active) begin
      if ($realtime < last_oe_fall + tDOE) begin
        data_out = {DATA_BITS{1'bz}};
      end else if ($realtime < last_addr_change + tOHA) begin
        data_out = prev_data;
      end else if ($realtime < last_addr_change + tAA) begin
        data_out = {DATA_BITS{BAD_DATA}};
      end else begin
        data_out = sram[addr_i];
      end
    end else begin
      data_out = {DATA_BITS{1'bz}};
    end
  end

  // Write operation
  reg write_enable;

  always @(we_n_i, ce_n_i, addr_i) begin
    write_enable = 0;
    if (!we_n_i && !ce_n_i) begin
      #(tAW) write_enable = 1;
    end
  end

  always @(posedge write_enable) begin
    sram[addr_i] = data_in;
  end

endmodule
