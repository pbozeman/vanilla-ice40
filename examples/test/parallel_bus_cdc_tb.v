`include "testing.v"

`include "parallel_bus_cdc.v"

module parallel_bus_cdc_tb ();

  parameter BUS_WIDTH = 10;

  reg clk;
  reg ext_clk;
  reg [BUS_WIDTH-1:0] data_bus;
  wire [BUS_WIDTH-1:0] data;

  // uut
  parallel_bus_cdc #(
      .BUS_WIDTH(BUS_WIDTH)
  ) uut (
      .clk(clk),
      .ext_clk(ext_clk),
      .data_bus(data_bus),
      .data(data)
  );

  `TEST_SETUP(parallel_bus_cdc_tb)

  // main clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // external clock
  initial begin
    ext_clk = 0;
    forever #7 ext_clk = ~ext_clk;
  end

  initial begin
    // setup
    data_bus = 0;
    repeat (5) @(posedge clk);

    // Test case 1: Single value transition
    data_bus = 10'b1010101010;
    @(negedge ext_clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    `ASSERT(data == 10'b1010101010)

    // Test case 2: Multiple transitions
    repeat (10) begin
      data_bus = $random;
      @(negedge ext_clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      `ASSERT(data == data_bus)
    end

    // Test case 3: Rapid transitions
    repeat (20) begin
      data_bus = $random;
      @(negedge ext_clk);
    end
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    `ASSERT(data == data_bus)

    // End simulation
    #100;
    $finish;
  end

endmodule
