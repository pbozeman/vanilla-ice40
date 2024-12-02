`ifndef SRAM_MODEL_V
`define SRAM_MODEL_V

`include "directives.sv"

// verilator lint_save
// verilator lint_off BLKSEQ
// verilator lint_off SYNCASYNCNET

module sram_model #(
    parameter ADDR_BITS                 = 10,
    parameter DATA_BITS                 = 8,
    parameter UNINITIALIZED_READS_FATAL = 1,
    parameter INJECT_ERROR              = 0,

    // timings (in ns)
    parameter real tAA  = 10,   // Address Access Time
    parameter real tOHA = 2.5,  // Output Hold Time
    parameter real tDOE = 6,    // OE# Access Time
    parameter real tAW  = 8,    // Address Setup Time to Write End

    parameter BAD_DATA = 1'bx
) (
    input logic                 we_n,
    input logic                 oe_n,
    input logic                 ce_n,
    input logic [ADDR_BITS-1:0] addr,
    inout logic [DATA_BITS-1:0] data_io
);

  // memory
  logic [DATA_BITS-1:0] sram_mem         [0:(1 << ADDR_BITS)-1];

  // data written to bus, possibly tri-state if output not enabled
  logic                 output_active;
  logic [DATA_BITS-1:0] data_out;


  // Previous data for output hold time
  logic [DATA_BITS-1:0] prev_data;

  // Time of last address change
  real                  last_addr_change;

  // Time of last OE# falling edge
  real                  last_oe_fall;

  // Data signals
  assign output_active = !ce_n && !oe_n;
  assign data_io       = output_active ? data_out : {DATA_BITS{1'bz}};

  // Delayed address update and data handling
  always @(addr) begin
    prev_data        = data_out;
    last_addr_change = $realtime;
  end

  // Track OE# falling edge
  always @(negedge oe_n) begin
    data_out     = {DATA_BITS{1'bz}};
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
        if (sram_mem[addr] === {DATA_BITS{1'bx}}) begin
          if (UNINITIALIZED_READS_FATAL) begin
            $display("read from unitialized addr %h", addr);
            $fatal;
          end else begin
            // verilator lint_off WIDTHTRUNC
            data_out = addr;
            // verilator lint_on WIDTHTRUNC
          end
        end else begin
          data_out = sram_mem[addr];
        end
      end
    end

    #1;
  end

  // Write operation
  logic write_enable = 0;

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
  // assign to sram_mem[addr], thus avoiding the latch warning,
  // we create a circular dependency that iverilog can't optimize
  // and the compile at >16 bits of addr space takes forever.
  // Hence, we allow latch creation below.
  //
  // verilator lint_off LATCH
  always @(*) begin
    if (write_enable) begin
      if (INJECT_ERROR && addr == {DATA_BITS{1'b1}}) begin
        sram_mem[addr] = {DATA_BITS{1'b1}};
      end else if (!we_n) begin
        sram_mem[addr] = data_io;
      end
    end
  end
  // verilator lint_on LATCH

  logic [ADDR_BITS-1:0] oe_n_initial_addr;
  logic [ADDR_BITS-1:0] we_n_initial_addr;
  logic [DATA_BITS-1:0] we_n_initial_data;

  logic                 reads_active = 0;
  logic                 writes_active = 0;

  always @(negedge oe_n) begin
    if (data_io !== {DATA_BITS{1'bz}}) begin
      $display("oe_n low while fpga driving bus");
      $fatal;
    end
    oe_n_initial_addr <= addr;
    reads_active      <= 1'b1;
  end

  always @(posedge oe_n) begin
    if (reads_active) begin
      if (oe_n_initial_addr != addr) begin
        $display("addr changed during read, old: %h new: %h",
                 oe_n_initial_addr, addr);
        $fatal;
      end
    end
  end

  always @(negedge we_n) begin
    we_n_initial_addr <= addr;
    we_n_initial_data <= data_io;
    writes_active     <= 1'b1;
  end

  always @(posedge we_n) begin
    if (writes_active) begin
      if (we_n_initial_addr !== addr) begin
        $display("addr changed during write");
        $fatal;
      end

      if (we_n_initial_data !== data_io) begin
        $display("data changed during write");
        $fatal;
      end
    end
  end

endmodule
// verilator lint_restore

`endif
