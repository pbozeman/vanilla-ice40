`include "testing.sv"

`include "fifo.sv"

module fifo_interleaved_tb;

  reg           clk = 1'b0;
  reg           reset = 1'b0;
  reg           write_en = 1'b0;
  reg           read_en = 1'b0;
  reg     [7:0] write_data = 8'b0;
  wire    [7:0] read_data;
  wire          empty;
  wire          full;

  integer       i;

  // for the interleaved test
  reg     [7:0] next_write_val;
  reg     [7:0] next_read_val;

  fifo uut (
      .clk       (clk),
      .reset     (reset),
      .write_en  (write_en),
      .read_en   (read_en),
      .write_data(write_data),
      .read_data (read_data),
      .empty     (empty),
      .full      (full)
  );

  // clock generator
  always #1 clk <= ~clk;

  `TEST_SETUP(fifo_interleaved_tb);

  initial begin
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
        write_en       = 1'b1;
        write_data     = next_write_val;
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
