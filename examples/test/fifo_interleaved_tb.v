`timescale 1ns / 1ps

module fifo_interleved_tb;

  reg clk = 1'b0;
  reg reset = 1'b0;
  reg write_en = 1'b0;
  reg read_en = 1'b0;
  reg [7:0] write_data = 8'b0;
  wire [7:0] read_data;
  wire empty;
  wire full;

  integer i;

  // for the interleaved test
  reg [7:0] next_write_val;
  reg [7:0] next_read_val;

  fifo uut (
      .clk_i(clk),
      .reset_i(reset),
      .write_en_i(write_en),
      .read_en_i(read_en),
      .write_data_i(write_data),
      .read_data_o(read_data),
      .empty_o(empty),
      .full_o(full)
  );

  // clock generator
  always #1 clk = ~clk;

  initial begin
    $dumpfile(".build/fifo_interleaved.vcd");
    $dumpvars(0, fifo_interleved_tb);

    // pause
    #5;

    //
    // Interleaved read/write
    //
    next_write_val = 0;
    next_read_val  = 0;
    for (i = 0; i < 512; i = i + 1) begin
      // write when we can
      if (!full) begin
        write_en = 1'b1;
        write_data = next_write_val;
        next_write_val = next_write_val + 1;
      end else begin
        write_en = 1'b0;
      end

      // read
      if (!empty && i % 20 == 0) begin
        read_en = 1'b1;
      end else begin
        read_en = 1'b0;
      end

      // only do the asserts if we actually read
      if (read_en) begin
        `ASSERT(read_data == next_read_val);
        next_read_val = next_read_val + 1;
      end

      @(posedge clk);
    end

    $finish;
  end

endmodule
