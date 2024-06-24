`timescale 1ns / 1ps

module uart_hello_tb;

  reg  clk = 1'b0;
  reg  reset = 1'b0;
  wire tx;
  wire led1;
  wire led2;

  uart_hello_fifo_top uut (
      .clk_i  (clk),
      .UART_TX(tx),
      .led1_o (led1),
      .led2_o (led2)
  );

  // clock generator
  always #1 clk = ~clk;

  initial begin
    $dumpfile(".build/uart_hello_fifo.vcd");
    $dumpvars(0, uut);

    // Run the simulation for 2 ms (2000 µs)
    #2000000;

    $finish;
  end

endmodule

