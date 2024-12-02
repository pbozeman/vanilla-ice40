`ifndef UART_TX_V
`define UART_TX_V

`include "directives.sv"

// 8n1 is hardcoded
module uart_tx #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 115_200
) (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] data_i,
    input  logic       tx_en_i,
    output logic       tx_ready,
    output logic       tx
);
  // Calculate required bit widths
  localparam CLOCKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;
  localparam CLK_COUNT_WIDTH = $clog2(CLOCKS_PER_BIT);
  localparam BIT_INDEX_WIDTH = 3;  // Fixed for 8 bits of data

  // State encoding
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] START = 2'b01;
  localparam [1:0] DATA = 2'b10;
  localparam [1:0] STOP = 2'b11;

  // sized comparison values
  localparam [CLK_COUNT_WIDTH-1:0] CLK_COUNT_MAX =
      CLK_COUNT_WIDTH'(CLOCKS_PER_BIT - 1);
  localparam [BIT_INDEX_WIDTH-1:0] BIT_INDEX_MAX = BIT_INDEX_WIDTH'(7);

  // State registers with explicit widths
  logic [                1:0] state = IDLE;
  logic [CLK_COUNT_WIDTH-1:0] clk_count = '0;
  logic [BIT_INDEX_WIDTH-1:0] bit_index = '0;
  logic [                7:0] data_buffer = '0;

  always_ff @(posedge clk) begin
    if (reset) begin
      state       <= IDLE;
      clk_count   <= '0;
      bit_index   <= '0;
      data_buffer <= '0;
      tx_ready    <= 1'b1;
      tx          <= 1'b1;
    end else begin
      case (state)
        IDLE: begin
          clk_count <= '0;
          if (tx_en_i) begin
            tx_ready    <= 1'b0;
            data_buffer <= data_i;
            state       <= START;
          end else begin
            tx_ready <= 1'b1;
          end
        end

        START: begin
          // start bit
          tx <= 1'b0;
          // hold for baud rate clocks and then move to send data
          if (clk_count < CLK_COUNT_MAX) begin
            clk_count <= clk_count + 1'b1;
          end else begin
            clk_count <= '0;
            state     <= DATA;
          end
        end

        DATA: begin
          // bit by bit send of data
          tx <= data_buffer[bit_index];
          // hold for baud rate clocks
          if (clk_count < CLK_COUNT_MAX) begin
            clk_count <= clk_count + 1'b1;
          end else begin
            // advance to next bit, or stop bit when done
            clk_count <= '0;
            if (bit_index < BIT_INDEX_MAX) begin
              bit_index <= bit_index + 1'b1;
            end else begin
              bit_index <= '0;
              state     <= STOP;
            end
          end
        end

        STOP: begin
          // stop bit
          tx <= 1'b1;
          // hold for baud rate clocks and then return to idle
          if (clk_count < CLK_COUNT_MAX) begin
            clk_count <= clk_count + 1'b1;
          end else begin
            tx_ready <= 1'b1;
            state    <= IDLE;
          end
        end
      endcase
    end
  end

endmodule

`endif
