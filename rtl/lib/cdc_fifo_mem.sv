`ifndef CDC_FIFO_MEM_V
`define CDC_FIFO_MEM_V

`include "directives.sv"

//
// From:
// http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
//
// 6.2 fifomem.v - FIFO memory buffer
//

module cdc_fifo_mem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_SIZE  = 4
) (
    input logic w_clk,
    input logic w_clk_en,
    input logic w_full,

    // write interface
    input logic [ ADDR_SIZE-1:0] w_addr,
    input logic [DATA_WIDTH-1:0] w_data,

    // read interface
    input  logic [ ADDR_SIZE-1:0] r_addr,
    output logic [DATA_WIDTH-1:0] r_data
);
  localparam DEPTH = 1 << ADDR_SIZE;
  logic [DATA_WIDTH-1:0] mem       [0:DEPTH-1];

  // Added for debugging in gtkwave, although, it might be nice to pass
  // this back out to callers. Presumably this will get optimized out
  // in a real build.
  // verilator lint_off UNUSEDSIGNAL
  logic                  discarded;
  // verilator lint_on UNUSEDSIGNAL

  always @(posedge w_clk) begin
    discarded <= 1'b0;

    if (w_clk_en) begin
      if (!w_full) begin
        mem[w_addr] <= w_data;
      end else begin
        discarded <= 1'b1;
      end
    end
  end

  assign r_data = mem[r_addr];

endmodule

`endif
