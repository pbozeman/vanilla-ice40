module blinky_top (
    input wire clk_i,
    output reg led1_o,
    output led2_o
);

  // 100 MHz clock
  parameter CLK_FREQ = 100_000_000;

  // blink every half second
  parameter HALF_SEC_COUNT = CLK_FREQ / 2;

  // 27-bit counter to hold counts up to 50 million
  reg [26:0] counter;

  always @(posedge clk_i) begin
    if (counter < HALF_SEC_COUNT - 1) begin
      counter <= counter + 1;
    end else begin
      counter <= 0;
      led1_o  <= ~led1_o;
    end
  end

  assign led2_o = 1'bZ;

endmodule
