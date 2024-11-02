`include "testing.v"
`include "cdc_fifo_mem.v"

`timescale 1ns / 1ps

module cdc_fifo_mem_tb;

  parameter DATA_WIDTH = 8;
  parameter ADDR_SIZE = 4;

  reg                   w_clk;
  reg                   w_clk_en;
  reg                   w_full;
  reg  [ ADDR_SIZE-1:0] w_addr;
  reg  [DATA_WIDTH-1:0] w_data;
  reg  [ ADDR_SIZE-1:0] r_addr;
  wire [DATA_WIDTH-1:0] r_data;

  cdc_fifo_mem #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_SIZE (ADDR_SIZE)
  ) uut (
      .w_clk   (w_clk),
      .w_clk_en(w_clk_en),
      .w_full  (w_full),
      .w_addr  (w_addr),
      .w_data  (w_data),
      .r_addr  (r_addr),
      .r_data  (r_data)
  );

  `TEST_SETUP(cdc_fifo_mem_tb)

  initial begin
    w_clk = 0;
    forever #5 w_clk = ~w_clk;
  end

  initial begin
    w_clk_en = 0;
    w_full   = 0;
    w_addr   = 0;
    w_data   = 0;
    r_addr   = 0;

    //
    // Test case 1: Write and read a single value
    //
    @(negedge w_clk);
    w_clk_en = 1;
    w_addr   = 4'b0000;
    w_data   = 8'hA5;
    @(posedge w_clk);

    @(negedge w_clk);
    w_clk_en = 0;
    r_addr   = 4'b0000;
    @(posedge w_clk);
    @(negedge w_clk);
    `ASSERT(r_data === 8'hA5)

    //
    // Test case 2: Write multiple values and read them back
    //
    @(negedge w_clk);
    w_clk_en = 1;
    w_addr   = 4'b0001;
    w_data   = 8'h55;
    @(posedge w_clk);

    @(negedge w_clk);
    w_addr = 4'b0010;
    w_data = 8'hFF;
    @(posedge w_clk);

    // read back
    @(negedge w_clk);
    w_clk_en = 0;
    r_addr   = 4'b0001;
    @(posedge w_clk);

    @(negedge w_clk);
    `ASSERT(r_data === 8'h55)

    r_addr = 4'b0010;
    @(posedge w_clk);
    @(negedge w_clk);
    `ASSERT(r_data === 8'hFF)

    //
    // Test case 3: Write when full (should not change memory)
    //
    w_full   = 1;
    w_clk_en = 1;
    w_addr   = 4'b0001;
    w_data   = 8'h00;
    @(posedge w_clk);

    @(negedge w_clk);
    w_full   = 0;
    w_clk_en = 0;
    @(posedge w_clk);

    @(negedge w_clk);
    r_addr = 4'b0001;
    @(posedge w_clk);

    @(negedge w_clk);
    `ASSERT(r_data === 8'h55)

    $finish;
  end

endmodule
