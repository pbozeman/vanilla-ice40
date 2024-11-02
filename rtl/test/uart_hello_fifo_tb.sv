`include "testing.sv"

`include "uart_hello_fifo_top.sv"

// verilator lint_off UNUSEDSIGNAL
module uart_hello_fifo_tb;

  logic clk = 1'b0;
  logic reset = 1'b0;
  logic tx;
  logic led1;
  logic led2;

  uart_hello_fifo_top uut (
      .CLK    (clk),
      .UART_TX(tx),
      .LED1   (led1),
      .LED2   (led2)
  );

  // clock generator
  always #1 clk <= ~clk;

  `TEST_SETUP(uart_hello_fifo_tb);

  initial begin
    #20000;
    $finish;
  end

endmodule
// verilator lint_on UNUSEDSIGNAL

