`ifndef UART_HELLO_TOP_V
`define UART_HELLO_TOP_V

`include "directives.sv"

`include "uart_tx.sv"

module uart_hello_top (
    input  logic CLK,
    output logic UART_TX,

    output logic LED1,
    output logic LED2
);
  // Message to send
  logic [7:0] message         [0:14];

  logic       initialized = 0;

  logic [3:0] msg_index = 0;
  logic [7:0] tx_data;
  logic       tx_send = 0;
  logic       reset = 0;
  logic       tx_ready;

  uart_tx #(
      .CLOCK_FREQ(100_000_000),
      .BAUD_RATE (115_200)
  ) uart_tx_inst (
      .clk     (CLK),
      .reset   (reset),
      .data_i  (tx_data),
      .tx_en_i (tx_send),
      .tx_ready(tx_ready),
      .tx      (UART_TX)
  );

  always @(posedge CLK) begin
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

  assign LED1 = 1'bZ;
  assign LED2 = 1'bZ;

endmodule

`endif
