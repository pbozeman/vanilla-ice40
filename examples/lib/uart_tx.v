// 8n1 is hardcoded

// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module uart_tx #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 115_200
) (
    input wire clk,
    input wire reset,
    input wire [7:0] data_i,
    input wire tx_en_i,
    output reg tx_ready,
    output reg tx
);

  localparam CLOCKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;

  // state machine states
  localparam IDLE = 2'b00;
  localparam START = 2'b01;
  localparam DATA = 2'b10;
  localparam STOP = 2'b11;

  reg [ 1:0] state = IDLE;
  reg [13:0] clk_count = 0;
  reg [ 2:0] bit_index = 0;
  reg [ 7:0] data_buffer = 0;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
      clk_count <= 0;
      bit_index <= 0;
      data_buffer <= 0;
      tx_ready <= 1;
      tx <= 1;
    end else begin
      case (state)
        IDLE: begin
          clk_count <= 0;
          if (tx_en_i) begin
            tx_ready <= 0;
            data_buffer <= data_i;
            state <= START;
          end else begin
            tx_ready <= 1;
          end
        end
        START: begin
          // start bit
          tx <= 0;
          // hold for baud rate clocks and then move to send data
          if (clk_count < CLOCKS_PER_BIT - 1) begin
            clk_count <= clk_count + 1;
          end else begin
            clk_count <= 0;
            state <= DATA;
          end
        end
        DATA: begin
          // bit by bit send of data
          tx <= data_buffer[bit_index];
          // hold for baud rate clocks
          if (clk_count < CLOCKS_PER_BIT - 1) begin
            clk_count <= clk_count + 1;
          end else begin
            // advance to next bit, or stop bit when done
            clk_count <= 0;
            if (bit_index < 7) begin
              bit_index <= bit_index + 1;
            end else begin
              bit_index <= 0;
              state <= STOP;
            end
          end
        end
        STOP: begin
          // stop bit
          tx <= 1;
          // hold for baud rate clocks and then return to idle
          if (clk_count < CLOCKS_PER_BIT - 1) begin
            clk_count <= clk_count + 1;
          end else begin
            tx_ready <= 1;
            state <= IDLE;
          end
        end
      endcase
    end
  end

endmodule
