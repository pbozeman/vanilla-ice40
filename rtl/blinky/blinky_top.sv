`include "directives.sv"

module blinky_top (
    input  logic CLK,
    output logic LED1,
    output       LED2
);

  // 100 MHz clock
  parameter CLK_FREQ = 100_000_000;

  // blink every half second
  parameter HALF_SEC_COUNT = CLK_FREQ / 2;

  // 27-bit counter to hold counts up to 50 million
  logic [26:0] counter;

  always_ff @(posedge CLK) begin
    if (counter < HALF_SEC_COUNT - 1) begin
      counter <= counter + 1;
    end else begin
      counter <= 0;
      LED1    <= ~LED1;
    end
  end

  assign LED2 = 1'bZ;

endmodule
