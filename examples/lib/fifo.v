// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
) (
    input  wire                  clk_i,
    input  wire                  reset_i,
    input  wire                  write_en_i,
    input  wire                  read_en_i,
    input  wire [DATA_WIDTH-1:0] write_data_i,
    output reg  [DATA_WIDTH-1:0] read_data_o,
    output wire                  empty_o,
    output wire                  full_o
);
  reg [DATA_WIDTH-1:0] fifo_mem[0:DEPTH-1];
  reg [$clog2(DEPTH)-1:0] wr_ptr = 0;
  reg [$clog2(DEPTH)-1:0] rd_ptr = 0;
  reg [$clog2(DEPTH+1)-1:0] fifo_count = 0;

  assign full_o  = (fifo_count == DEPTH);
  assign empty_o = (fifo_count == 0);

  // Write operation
  always @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      wr_ptr <= 0;
    end else if (write_en_i && !full_o) begin
      fifo_mem[wr_ptr] <= write_data_i;
      wr_ptr <= (wr_ptr + 1) % DEPTH;
    end
  end

  // Read operation
  always @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      rd_ptr <= 0;
      read_data_o <= 0;
    end else if (read_en_i && !empty_o) begin
      read_data_o <= fifo_mem[rd_ptr];
      rd_ptr <= (rd_ptr + 1) % DEPTH;
    end
  end

  // FIFO count management
  always @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      fifo_count <= 0;
    end else begin
      case ({
        ({write_en_i && !full_o, read_en_i && !empty_o})
      })
        2'b01:   fifo_count <= fifo_count - 1;
        2'b10:   fifo_count <= fifo_count + 1;
        default: fifo_count <= fifo_count;
      endcase
    end
  end
endmodule
