`ifndef FIFO_V
`define FIFO_V

`include "directives.sv"

module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
) (
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  write_en,
    input  logic                  read_en,
    input  logic [DATA_WIDTH-1:0] write_data,
    output logic [DATA_WIDTH-1:0] read_data,
    output logic                  empty,
    output logic                  full
);
  logic [     DATA_WIDTH-1:0] fifo_mem       [0:DEPTH-1];
  logic [  $clog2(DEPTH)-1:0] wr_ptr = 0;
  logic [  $clog2(DEPTH)-1:0] rd_ptr = 0;
  logic [$clog2(DEPTH+1)-1:0] fifo_count = 0;

  // Write operation
  always_ff @(posedge clk) begin
    if (reset) begin
      wr_ptr <= 0;
    end else if (write_en && !full) begin
      fifo_mem[wr_ptr] <= write_data;
      wr_ptr           <= (wr_ptr + 1) % DEPTH;
    end
  end

  // Read operation
  always_ff @(posedge clk) begin
    if (reset) begin
      rd_ptr    <= 0;
      read_data <= 0;
    end else if (read_en && !empty) begin
      read_data <= fifo_mem[rd_ptr];
      rd_ptr    <= (rd_ptr + 1) % DEPTH;
    end
  end

  // FIFO count management
  always_ff @(posedge clk) begin
    if (reset) begin
      fifo_count <= 0;
    end else begin
      case ({
        ({write_en && !full, read_en && !empty})
      })
        2'b01:   fifo_count <= fifo_count - 1;
        2'b10:   fifo_count <= fifo_count + 1;
        default: fifo_count <= fifo_count;
      endcase
    end
  end

  assign full  = (fifo_count == DEPTH);
  assign empty = (fifo_count == 0);

endmodule

`endif
