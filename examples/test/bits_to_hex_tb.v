// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module bits_to_hex_tb;

  reg clk = 1'b0;
  reg reset = 1'b0;

  reg [7:0] bits_8 = 0;
  wire [15:0] ascii_8;

  bits_to_hex #(
      .N_BITS(8)
  ) uut_8bits (
      .clk_i  (clk),
      .reset_i(reset),
      .bits_i (bits_8),
      .ascii_o(ascii_8)
  );

  reg  [ 6:0] bits_7 = 0;
  wire [15:0] ascii_7;

  bits_to_hex #(
      .N_BITS(7)
  ) uut_7bits (
      .clk_i  (clk),
      .reset_i(reset),
      .bits_i (bits_7),
      .ascii_o(ascii_7)
  );

  reg  [ 63:0] bits_64 = 0;
  wire [127:0] ascii_64;

  bits_to_hex #(
      .N_BITS(64)
  ) uut_64bits (
      .clk_i  (clk),
      .reset_i(reset),
      .bits_i (bits_64),
      .ascii_o(ascii_64)
  );

  // clock generator
  always #1 clk = ~clk;

  initial begin
    $dumpfile(".build/bits_to_hex.vcd");
    $dumpvars(0, bits_to_hex_tb);

    // pause
    #5;

    //
    // Test 0 case - 8 bits
    //
    bits_8 = 0;
    @(posedge clk);

    `ASSERT(ascii_8 == "00");

    //
    // Test A - 8 bits
    //
    bits_8 = 10;
    @(posedge clk);

    `ASSERT(ascii_8 == "0A");

    //
    // Test FF - 8 bits
    //
    bits_8 = 255;
    @(posedge clk);

    `ASSERT(ascii_8 == "FF");

    //
    // Test 7F - 7 bits
    //
    bits_7 = 127;
    @(posedge clk);

    `ASSERT(ascii_7 == "7F");

    //
    // biggie
    //
    bits_64 = 64'hAAAAAAAAAAAAAAAA;
    @(posedge clk);

    `ASSERT(ascii_64 == "AAAAAAAAAAAAAAAA");

    $finish;
  end

endmodule
