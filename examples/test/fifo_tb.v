`include "testing.v"

`include "fifo.v"

module fifo_tb;

  reg           clk = 1'b0;
  reg           reset = 1'b0;
  reg           write_en = 1'b0;
  reg           read_en = 1'b0;
  reg     [7:0] write_data = 8'b0;
  wire    [7:0] read_data;
  wire          empty;
  wire          full;

  integer       i;

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

  `TEST_SETUP(fifo_tb);

  initial begin
    // pause
    #5;

    //
    // Initial state test
    //

    // clear regs
    write_en   = 1'b0;
    write_data = 8'h00;
    @(posedge clk);
    @(negedge clk);

    `ASSERT(empty);
    `ASSERT(!full);

    //
    // Single write/read test
    //

    // push a value
    write_en   = 1'b1;
    write_data = 8'hA5;
    @(posedge clk);
    @(negedge clk);

    `ASSERT(!empty);
    `ASSERT(!full);

    // clear our side
    write_en   = 1'b0;
    write_data = 8'h00;
    @(posedge clk);
    @(negedge clk);

    // `ASSERT(!empty);
    `ASSERT(!full);

    @(posedge clk);
    @(negedge clk);

    // `ASSERT(!empty);
    `ASSERT(!full);

    read_en = 1'b1;
    @(posedge clk);
    @(negedge clk);

    `ASSERT(empty);
    `ASSERT(!full);
    `ASSERT(read_data == 8'hA5);

    read_en = 1'b0;
    `ASSERT(empty);
    `ASSERT(!full);

    //
    // Fill and drain fifo test
    //

    // push one less than size
    for (i = 0; i < 15; i = i + 1) begin
      write_en   = 1'b1;
      write_data = i;
      @(posedge clk);
      @(negedge clk);
      `ASSERT(!empty);
      `ASSERT(!full);
    end

    // write the final byte
    write_en   = 1'b1;
    write_data = 8'h0F;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(full);

    // clock a value that shouldn't get included
    write_data = 8'hAA;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(full);

    // clear write
    write_en   = 1'b0;
    write_data = 8'h00;
    @(posedge clk);
    @(negedge clk);

    // read all but 1 back
    for (i = 0; i < 15; i = i + 1) begin
      read_en = 1'b1;
      @(posedge clk);
      @(negedge clk);
      `ASSERT(!empty);
      `ASSERT(!full);
      `ASSERT(read_data == i);
    end

    // read final byte
    read_en = 1'b1;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(empty);
    `ASSERT(!full);
    `ASSERT(read_data == 8'h0F);

    $finish;
  end

endmodule
