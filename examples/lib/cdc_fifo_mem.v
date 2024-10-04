`ifndef CDC_FIFO_MEM_V
`define CDC_FIFO_MEM_V

`include "directives.v"

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
    input wire w_clk,
    input wire w_clk_en,
    input wire w_full,

    // write interface
    input wire [ ADDR_SIZE-1:0] w_addr,
    input wire [DATA_WIDTH-1:0] w_data,

    // read interface
    input  wire [ ADDR_SIZE-1:0] r_addr,
    output wire [DATA_WIDTH-1:0] r_data
);
  localparam DEPTH = 1 << ADDR_SIZE;
  reg [DATA_WIDTH-1:0] mem[0:DEPTH-1];

  always @(posedge w_clk) begin
    if (w_clk_en && !w_full) begin
      mem[w_addr] <= w_data;
    end
  end

  assign r_data = mem[r_addr];

endmodule

`endif
