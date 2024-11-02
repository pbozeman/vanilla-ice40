// Module: bits_to_hex
//
// Converts a binary input to its ASCII hexadecimal representation.
//
// Parameters:
//    N_BITS - Number of input bits.
// Outputs:
//    ascii - Array of ASCII characters, sized to (N_BITS+3)/4.
// Usage:
//    Declare ascii in the instantiating module as follows:
//    localparam SIZE = (N_BITS + 3) / 4;
//    logic [7:0] ascii[SIZE-1:0];
//
// The expression (N_BITS + 3) / 4 is used to ensure rounding up when the total
// number of bits isn't a multiple of 4. Adding 3 before dividing by 4
// effectively performs a ceiling function on the division, ensuring
// that any remainder in the division results in rounding up to the next
// whole nibble. This is crucial to accommodate all bits in the conversion
// to hexadecimal ASCII characters:
// - For 1 to 4 bits, 1 nibble is needed.
// - For 5 to 8 bits, 2 nibbles are needed, and so on.

`ifndef BITS_TO_HEX_V
`define BITS_TO_HEX_V

`include "directives.sv"

module bits_to_hex #(
    parameter N_BITS = 32
) (
    input  logic                        clk,
    input  logic                        reset,
    input  logic [          N_BITS-1:0] bits,
    output logic [8*((N_BITS+3)/4)-1:0] ascii
);
  // Calculate number of nibbles needed
  localparam N_NIBBLES = (N_BITS + 3) / 4;

  // Local variable for loop and nibble extraction
  integer i;

  // Binary to ASCII conversion for a single nibble
  function [7:0] nibble_to_ascii(input [3:0] nibble);
    begin
      if (nibble < 10) nibble_to_ascii = "0" + nibble;
      else nibble_to_ascii = "A" + (nibble - 10);
    end
  endfunction

  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < N_NIBBLES; i = i + 1) begin
        ascii[i*8+:8] <= 8'd0;
      end
    end else begin
      // This will get expanded during synthesis
      for (i = 0; i < N_NIBBLES; i = i + 1) begin
        // Handle partial nibbles by 0 padding them
        if (i == N_NIBBLES - 1 && (N_BITS % 4) != 0) begin
          case (N_BITS % 4)
            1:
            ascii[i*8+:8] <= nibble_to_ascii({3'b000, bits[N_BITS-1:N_BITS-1]});
            2:
            ascii[i*8+:8] <= nibble_to_ascii({2'b00, bits[N_BITS-1:N_BITS-2]});
            3:
            ascii[i*8+:8] <= nibble_to_ascii({1'b0, bits[N_BITS-1:N_BITS-3]});
            default: ascii[i*8+:8] <= 8'd0;  // Should not occur
          endcase
        end else begin
          // Process full nibbles
          ascii[i*8+:8] <= nibble_to_ascii(bits[(i*4)+:4]);
        end
      end
    end
  end

endmodule

`endif
