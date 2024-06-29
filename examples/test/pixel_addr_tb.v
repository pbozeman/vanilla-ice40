`timescale 1ns / 1ps

module pixel_addr_tb;
  reg clk;
  reg reset;
  wire [9:0] column;
  wire [9:0] row;

  pixel_addr uut (
      .clk(clk),
      .reset(reset),
      .column(column),
      .row(row)
  );

  always begin
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile(".build/pixel_addr_dump.vcd");
    $dumpvars(0, pixel_addr_tb);

    clk   = 0;
    reset = 0;

    // Reset
    reset = 1;
    `ASSERT(column == 0);
    `ASSERT(row == 0);
    @(posedge clk);
    reset = 0;
    `ASSERT(column == 0);
    `ASSERT(row == 0);

    @(posedge clk);
    `ASSERT(column == 1);
    `ASSERT(row == 0);

    @(posedge clk);
    `ASSERT(column == 2);
    `ASSERT(row == 0);

    // Advance to end of line
    repeat (797) @(posedge clk);
    `ASSERT(column == 799);
    `ASSERT(row == 0);

    // Row should roll over
    @(posedge clk);
    `ASSERT(column == 0);
    `ASSERT(row == 1);

    // Advance to next line
    repeat (800) @(posedge clk);
    `ASSERT(column == 0);
    `ASSERT(row == 2);

    // Advance to next line
    repeat (522) repeat (800) @(posedge clk);
    `ASSERT(column == 0);
    `ASSERT(row == 524);

    // Should advance to next frame
    repeat (800) @(posedge clk);
    `ASSERT(column == 0);
    `ASSERT(row == 0);

    $finish;
  end
endmodule

