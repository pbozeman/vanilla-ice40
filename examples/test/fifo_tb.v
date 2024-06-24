`timescale 1ns / 1ps

module fifo_tb;

  reg clk = 1'b0;
  reg reset = 1'b0;
  reg write_en = 1'b0;
  reg read_en = 1'b0;
  reg [7:0] write_data = 8'b0;
  wire [7:0] read_data;
  wire empty;
  wire full;

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
    $dumpfile(".build/fifo.vcd");
    $dumpvars(0, uut);

    // TODO: add asserts, etc

    // Apply reset
    reset = 1'b1;
    #5;
    reset = 1'b0;

    // Write some data to the FIFO
    #10;
    write_en   = 1'b1;
    write_data = 8'hA5;
    #2;
    write_en = 1'b0;

    // Read the data from the FIFO
    #10;
    read_en = 1'b1;
    #2;
    read_en = 1'b0;

    // Run the simulation for 2 ms (2000 µs)
    #2000000;

    $finish;
  end

endmodule
