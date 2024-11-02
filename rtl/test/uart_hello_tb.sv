`include "testing.sv"

`include "uart_hello_top.sv"
`include "uart_tx.sv"

// verilator lint_off UNUSEDSIGNAL
module uart_hello_tb;

  reg  clk = 1'b0;
  reg  reset = 1'b0;
  wire tx;
  wire led1;
  wire led2;

  uart_hello_top uut (
      .CLK    (clk),
      .UART_TX(tx),
      .LED1   (led1),
      .LED2   (led2)
  );

  // clock generator
  always #1 clk <= ~clk;

  `TEST_SETUP(uart_hello_tb);

  initial begin
    #20000;
    $finish;
  end

endmodule

// verilator lint_on UNUSEDSIGNAL
