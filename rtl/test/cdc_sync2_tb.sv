`include "testing.sv"
`include "cdc_sync2.sv"

module cdc_sync2_tb;

  parameter WIDTH = 4;

  reg              clk;
  reg              rst_n;
  reg  [WIDTH-1:0] d;
  wire [WIDTH-1:0] q;

  cdc_sync2 #(
      .WIDTH(WIDTH)
  ) uut (
      .clk  (clk),
      .rst_n(rst_n),
      .d    (d),
      .q    (q)
  );

  // Clock generation
  always #5 clk <= ~clk;

  `TEST_SETUP(cdc_sync2_tb)

  initial begin
    // Initialize inputs
    clk   = 0;
    rst_n = 0;
    d     = 0;

    // Wait for global reset
    repeat (10) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
    @(negedge clk);

    // Test case 1: Normal operation
    @(posedge clk);
    @(negedge clk);
    d = 4'b1010;

    @(posedge clk);
    @(negedge clk);
    `ASSERT(q == 4'b0000);

    @(posedge clk);
    @(negedge clk);
    `ASSERT(q == 4'b1010);

    // Test case 2: Changing input
    @(posedge clk);
    @(negedge clk);
    d = 4'b0101;

    @(posedge clk);
    @(negedge clk);
    `ASSERT(q == 4'b1010);

    @(posedge clk);
    @(negedge clk);
    `ASSERT(q == 4'b0101);

    // Test case 3: Reset operation
    @(posedge clk);
    rst_n = 0;

    @(posedge clk);
    @(negedge clk);
    `ASSERT(q == 4'b0000);

    rst_n = 1;
    d     = 4'b1111;
    @(posedge clk);
    @(negedge clk);
    `ASSERT(q == 4'b0000);

    @(posedge clk);
    @(negedge clk);
    `ASSERT(q == 4'b1111);

    // Test case 4: Rapid input changes
    repeat (10) begin
      @(posedge clk) d = $random;
    end
    @(posedge clk);
    d = 4'b1100;

    @(posedge clk);
    @(posedge clk);
    `ASSERT(q == 4'b1100);

    repeat (10) @(posedge clk);
    $finish;
  end

endmodule
