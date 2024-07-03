// for simulation
`timescale 1ns / 1ps

module vga_sync_tb;

  reg clk = 1'b0;
  reg reset = 1'b0;
  wire visible;
  wire hsync;
  wire vsync;
  wire [9:0] column;
  wire [9:0] row;

  reg [3:0] frames = 0;

  vga_sync uut (
      .clk(clk),
      .reset(reset),
      .visible(visible),
      .hsync(hsync),
      .vsync(vsync),
      .column(column),
      .row(row)
  );

  // clock generator
  always #1 clk = ~clk;

  initial begin
    $dumpfile(".build/vga_dump.vcd");
    $dumpvars(0, vga_sync_tb);

    // 3 frames
    repeat (3 * 800 * 600) @(posedge clk);

    // Make sure we actually did stuff
    `ASSERT(frames == 3);

    $display("Simulation end, SUCCESS!");
    $finish;
  end

  // invariants
  always @(posedge clk) begin
    `ASSERT(column < 800)
    `ASSERT(row < 525)

    // visible should only be on for display area
    if (column < 640 && row < 480) begin
      `ASSERT(visible)
    end else begin
      `ASSERT(!visible)
    end

    // vsync should only be on for lines 490 and 491
    if (row == 490 || row == 491) begin
      // Low active
      `ASSERT(!vsync)
    end else begin
      `ASSERT(vsync)
    end

    // hsync test
    if (column >= 656 && column < 752) begin
      `ASSERT(!hsync)
    end else begin
      `ASSERT(hsync);
    end

    if (row == 524 && column == 799) begin
      frames <= frames + 1;
    end
  end
endmodule