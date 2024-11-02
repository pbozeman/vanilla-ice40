`ifndef UART_FIFO_TOP_V
`define UART_FIFO_TOP_V

`include "directives.sv"

`include "fifo.sv"
`include "uart_tx.sv"

module uart_hello_fifo_top (
    input  logic CLK,
    output logic UART_TX,

    output logic LED1,
    output logic LED2
);
  logic       reset = 0;
  logic       initialized = 0;

  // Message to send
  logic [7:0] message           [0:14];
  logic [3:0] msg_index = 0;

  // UART signal
  logic       tx_ready;

  // FIFO signals
  logic [7:0] fifo_write_data;
  logic       fifo_write_en = 0;

  logic [7:0] fifo_read_data;
  logic       fifo_read_en;

  logic       fifo_empty;
  logic       fifo_full;

  // UART transmitter instantiation
  uart_tx #(
      .CLOCK_FREQ(100_000_000),
      .BAUD_RATE (115_200)
  ) uart_tx_inst (
      .clk     (CLK),
      .reset   (reset),
      .data_i  (fifo_read_data),
      .tx_en_i (!fifo_empty),
      .tx_ready(tx_ready),
      .tx      (UART_TX)
  );

  // FIFO instantiation
  fifo #(
      .DEPTH(16)
  ) fifo_inst (
      .clk       (CLK),
      .reset     (reset),
      .write_en  (fifo_write_en),
      .read_en   (fifo_read_en),
      .write_data(fifo_write_data),
      .read_data (fifo_read_data),
      .empty     (fifo_empty),
      .full      (fifo_full)
  );

  // Continuous assignment for fifo_read_en
  assign fifo_read_en = tx_ready && !fifo_empty;

  always_ff @(posedge CLK) begin
    if (!initialized) begin
      message[0]    <= "H";
      message[1]    <= "e";
      message[2]    <= "l";
      message[3]    <= "l";
      message[4]    <= "o";
      message[5]    <= ",";
      message[6]    <= " ";
      message[7]    <= "F";
      message[8]    <= "i";
      message[9]    <= "f";
      message[10]   <= "o";
      message[11]   <= "!";
      message[12]   <= "!";
      message[13]   <= 8'h0D;
      message[14]   <= 8'h0A;
      initialized   <= 1;
      fifo_write_en <= 1;
    end
  end

  always_ff @(posedge CLK) begin
    if (initialized && msg_index < 15 && !fifo_full) begin
      fifo_write_data <= message[msg_index];
      msg_index       <= msg_index + 1;
    end else if (msg_index == 15) begin
      msg_index <= 0;
    end
  end

  assign LED1 = 1'b0;
  assign LED2 = 1'b0;

endmodule

`endif
