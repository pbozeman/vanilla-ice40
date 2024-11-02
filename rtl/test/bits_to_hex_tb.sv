`include "testing.sv"

`include "bits_to_hex.sv"

module bits_to_hex_tb;

  logic        clk = 1'b0;
  logic        reset = 1'b0;

  logic [ 7:0] bits_8 = 0;
  logic [15:0] ascii_8;

  bits_to_hex #(
      .N_BITS(8)
  ) uut_8bits (
      .clk  (clk),
      .reset(reset),
      .bits (bits_8),
      .ascii(ascii_8)
  );

  logic [ 6:0] bits_7 = 0;
  logic [15:0] ascii_7;

  bits_to_hex #(
      .N_BITS(7)
  ) uut_7bits (
      .clk  (clk),
      .reset(reset),
      .bits (bits_7),
      .ascii(ascii_7)
  );

  logic [ 63:0] bits_64 = 0;
  logic [127:0] ascii_64;

  bits_to_hex #(
      .N_BITS(64)
  ) uut_64bits (
      .clk  (clk),
      .reset(reset),
      .bits (bits_64),
      .ascii(ascii_64)
  );

  // clock generator
  always #1 clk <= ~clk;

  `TEST_SETUP(bits_to_hex_tb);

  initial begin
    // pause
    #5;

    //
    // Test 0 case - 8 bits
    //
    bits_8 = 0;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(ascii_8 == "00");

    //
    // Test A - 8 bits
    //
    bits_8 = 10;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(ascii_8 == "0A");

    //
    // Test FF - 8 bits
    //
    bits_8 = 255;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(ascii_8 == "FF");

    //
    // Test 7F - 7 bits
    //
    bits_7 = 127;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(ascii_7 == "7F");

    //
    // biggie
    //
    bits_64 = 64'hAAAAAAAAAAAAAAAA;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(ascii_64 == "AAAAAAAAAAAAAAAA");

    $finish;
  end

endmodule
