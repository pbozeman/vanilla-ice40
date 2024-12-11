`include "testing.sv"

`include "axi_stripe_router.sv"

module axi_stripe_router_tb;
  parameter SEL_BITS = 2;
  parameter AXI_ADDR_WIDTH = 20;

  logic                      clk;
  logic                      axi_resetn;
  logic [AXI_ADDR_WIDTH-1:0] axi_addr;
  logic                      axi_avalid;
  logic                      req_accepted;
  logic                      resp_accepted;
  logic [        SEL_BITS:0] req;
  logic [        SEL_BITS:0] resp;

  axi_stripe_router #(
      .SEL_BITS      (SEL_BITS),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
  ) uut (
      .axi_clk      (clk),
      .axi_resetn   (axi_resetn),
      .axi_addr     (axi_addr),
      .axi_avalid   (axi_avalid),
      .req_accepted (req_accepted),
      .resp_accepted(resp_accepted),
      .req          (req),
      .resp         (resp)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  `TEST_SETUP(axi_stripe_router_tb)

  // verilator lint_off UNUSEDSIGNAL
  logic [8:0] test_line;
  // verilator lint_on UNUSEDSIGNAL

  task setup();
    begin
      @(posedge clk);
      axi_resetn    = 0;
      axi_addr      = 0;
      axi_avalid    = 0;
      req_accepted  = 0;
      resp_accepted = 0;

      @(posedge clk);
      axi_resetn = 1;
      @(posedge clk);
    end
  endtask

  task send_request(input [AXI_ADDR_WIDTH-1:0] addr);
    begin
      axi_addr   = addr;
      axi_avalid = 1;
      @(posedge clk);
      #1;
      axi_avalid = 0;
    end
  endtask

  task accept_request();
    begin
      req_accepted = 1;
      @(posedge clk);
      #1;
      req_accepted = 0;
    end
  endtask

  task accept_response();
    begin
      resp_accepted = 1;
      @(posedge clk);
      #1;
      resp_accepted = 0;
    end
  endtask

  task test_basic_routing();
    begin
      test_line = `__LINE__;
      setup();

      send_request(20'h00002);
      `ASSERT_EQ(req, 3'b010)
      accept_request();
      `ASSERT_EQ(resp, 3'b010)
      accept_response();
      `ASSERT_EQ(resp, 3'b111)
    end
  endtask

  task test_multiple_requests();
    begin
      test_line = `__LINE__;
      setup();

      send_request(20'h00001);
      `ASSERT_EQ(req, 3'b001)
      accept_request();

      send_request(20'h00002);
      `ASSERT_EQ(req, 3'b010)
      accept_request();

      `ASSERT_EQ(resp, 3'b001)
      accept_response();
      `ASSERT_EQ(resp, 3'b010)
      accept_response();
      `ASSERT_EQ(resp, 3'b111)
    end
  endtask

  task test_idle_response();
    begin
      test_line = `__LINE__;
      setup();

      `ASSERT_EQ(resp, 3'b111)
      send_request(20'h00003);
      `ASSERT_EQ(req, 3'b011)
      accept_request();
      `ASSERT_EQ(resp, 3'b011)
    end
  endtask

  task test_request_hold();
    begin
      test_line = `__LINE__;
      setup();

      send_request(20'h00002);
      `ASSERT_EQ(req, 3'b010)
      @(posedge clk);
      #1;
      `ASSERT_EQ(req, 3'b010)
      accept_request();
      accept_response();
    end
  endtask

  initial begin
    test_basic_routing();
    test_multiple_requests();
    test_idle_response();
    test_request_hold();

    #100;
    $finish;
  end

endmodule
