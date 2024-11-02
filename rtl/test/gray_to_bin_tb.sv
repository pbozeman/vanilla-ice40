`include "testing.sv"
`include "gray_to_bin.sv"

module gray_to_bin_tb;

  parameter WIDTH = 4;

  logic [WIDTH-1:0] gray;
  logic [WIDTH-1:0] bin;

  gray_to_bin #(
      .WIDTH(WIDTH)
  ) dut (
      .gray(gray),
      .bin (bin)
  );

  `TEST_SETUP(gray_to_bin_tb)

  logic clk;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    gray = 0;
    @(posedge clk);

    // Test some specific cases
    gray = 4'b0000;
    @(posedge clk);
    `ASSERT(bin === 4'b0000)

    gray = 4'b0001;
    @(posedge clk);
    `ASSERT(bin === 4'b0001)

    gray = 4'b0011;
    @(posedge clk);
    `ASSERT(bin === 4'b0010)

    gray = 4'b0010;
    @(posedge clk);
    `ASSERT(bin === 4'b0011)

    gray = 4'b0110;
    @(posedge clk);
    `ASSERT(bin === 4'b0100)

    gray = 4'b1111;
    @(posedge clk);
    `ASSERT(bin === 4'b1010)

    $finish;
  end

endmodule
