// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module uart_hello_top (
    input  wire clk_i,
    output wire UART_TX,

    output wire led1_o,
    output wire led2_o
);
  // Message to send
  reg [7:0] message[0:14];

  reg initialized = 0;

  reg [3:0] msg_index = 0;
  reg [7:0] tx_data;
  reg tx_send = 0;
  wire reset = 0;
  wire tx_ready;

  uart_tx #(
      .CLOCK_FREQ(100_000_000),
      .BAUD_RATE (115_200)
  ) uart_tx_inst (
      .clk_i(clk_i),
      .reset_i(reset),
      .data_i(tx_data),
      .tx_en_i(tx_send),
      .tx_ready_o(tx_ready),
      .tx_o(UART_TX)
  );

  always @(posedge clk_i) begin
    if (!initialized) begin
      message[0]  <= "H";
      message[1]  <= "e";
      message[2]  <= "l";
      message[3]  <= "l";
      message[4]  <= "o";
      message[5]  <= ",";
      message[6]  <= " ";
      message[7]  <= "W";
      message[8]  <= "o";
      message[9]  <= "r";
      message[10] <= "l";
      message[11] <= "d";
      message[12] <= "!";
      message[13] <= 8'h0D;
      message[14] <= 8'h0A;
      initialized <= 1;
    end else if (tx_ready) begin
      if (msg_index < 15) begin
        tx_data   <= message[msg_index];
        tx_send   <= 1;
        msg_index <= msg_index + 1;
      end else begin
        tx_send   <= 0;
        msg_index <= 0;
      end
    end
  end

  assign led1_o = 1'bZ;
  assign led2_o = 1'bZ;

endmodule
