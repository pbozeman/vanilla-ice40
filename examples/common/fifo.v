// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module fifo #(
    parameter FIFO_DEPTH = 16
) (
    input wire clk_i,
    input wire reset_i,
    input wire write_en_i,
    input wire read_en_i,
    input wire [7:0] write_data_i,
    output reg [7:0] read_data_o,
    output wire empty_o,
    output wire full_o
);

  reg [7:0] fifo_mem[0:FIFO_DEPTH-1];
  reg [3:0] write_ptr = 0;
  reg [3:0] read_ptr = 0;
  reg [4:0] fifo_count = 0;

  assign empty_o = (fifo_count == 0);
  assign full_o  = (fifo_count == FIFO_DEPTH);

  always @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      write_ptr  <= 0;
      read_ptr   <= 0;
      fifo_count <= 0;
    end else begin
      if (write_en_i && !full_o) begin
        fifo_mem[write_ptr] <= write_data_i;
        write_ptr <= write_ptr + 1;
        fifo_count <= fifo_count + 1;
      end
      if (read_en_i && !empty_o) begin
        read_data_o <= fifo_mem[read_ptr];
        read_ptr <= read_ptr + 1;
        fifo_count <= fifo_count - 1;
      end
    end
  end

endmodule
