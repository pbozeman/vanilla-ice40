`ifndef SYNC_FIFO_V
`define SYNC_FIFO_V

`include "directives.sv"


// Synchronous FIFO with parameterized width and depth Uses increment signals
// for read/write control
//
// This shares a similar interface to cdc_fifo, but works when the reader
// and writer are in the same clock domain.
//
// TODO: remove the old "fifo.sv" It's interface is not generally useful and
// was done before I knew what I wanted in a fifo module.

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_SIZE  = 4
) (
    input logic clk,
    input logic rst_n,

    input  logic                  w_inc,
    input  logic [DATA_WIDTH-1:0] w_data,
    output logic                  w_full,

    input  logic                  r_inc,
    output logic                  r_empty,
    output logic [DATA_WIDTH-1:0] r_data
);
  // Local parameters
  localparam DEPTH = 1 << ADDR_SIZE;

  logic [DATA_WIDTH-1:0] mem       [DEPTH-1:0];

  logic [   ADDR_SIZE:0] w_ptr = 0;
  logic [   ADDR_SIZE:0] r_ptr = 0;

  // Internal signals
  logic [ ADDR_SIZE-1:0] w_addr;
  logic [ ADDR_SIZE-1:0] r_addr;

  // Extract addresses from pointers
  assign w_addr = w_ptr[ADDR_SIZE-1:0];
  assign r_addr = r_ptr[ADDR_SIZE-1:0];

  // write
  always @(posedge clk) begin
    if (!rst_n) begin
      w_ptr <= 0;
    end else begin
      if (w_inc & !w_full) begin
        mem[w_addr] <= w_data;
        w_ptr       <= w_ptr + 1;
      end
    end
  end

  // read
  always @(posedge clk) begin
    if (!rst_n) begin
      r_ptr <= 0;
    end else begin
      if (r_inc & !r_empty) begin
        r_ptr <= r_ptr + 1;
      end
    end
  end

  assign w_full  = (w_ptr[ADDR_SIZE] ^ r_ptr[ADDR_SIZE]) && w_addr == r_addr;
  assign r_empty = (w_ptr == r_ptr);
  assign r_data  = mem[r_addr];

endmodule

`endif
