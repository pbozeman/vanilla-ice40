`timescale 1ns / 1ps

module uart_hello_tb;

  reg  clk = 1'b0;
  reg  reset = 1'b0;
  wire tx;
  wire led1;
  wire led2;

  uart_hello_top uut (
      .CLK(clk),
      .UART_TX(tx),
      .LED1(led1),
      .LED2(led2)
  );

  // clock generator
  always #1 clk = ~clk;

  initial begin
    $dumpfile(".build/uart_hello.vcd");
    $dumpvars(0, uut);

    // Run the simulation for 2 ms (2000 µs)
    #2000000;

    $finish;
  end

endmodule

