`include "testing.v"

`include "uart_hello_top.v"
`include "uart_tx.v"

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

  `TEST_SETUP(uart_hello_tb);

  initial begin
    #20000;
    $finish;
  end

endmodule

