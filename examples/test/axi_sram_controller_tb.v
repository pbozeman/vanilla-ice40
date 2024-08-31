`include "testing.v"
`include "axi_sram_controller.v"
`include "sram_model.v"

module axi_sram_controller_tb;
  localparam AXI_ADDR_WIDTH = 10;
  localparam AXI_DATA_WIDTH = 8;

  reg                       axi_aclk;
  reg                       axi_aresetn;

  // AXI-Lite Write Address Channel
  reg  [AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
  reg                       s_axi_awvalid;
  wire                      s_axi_awready;

  // AXI-Lite Write Data Channel
  reg  [AXI_DATA_WIDTH-1:0] s_axi_wdata;
  reg                       s_axi_wstrb;
  reg                       s_axi_wvalid;
  wire                      s_axi_wready;

  // AXI-Lite Write Response Channel
  wire [               1:0] s_axi_bresp;
  wire                      s_axi_bvalid;
  reg                       s_axi_bready;

  // AXI-Lite Read Address Channel
  reg  [AXI_ADDR_WIDTH-1:0] s_axi_araddr;
  reg                       s_axi_arvalid;
  wire                      s_axi_arready;

  // AXI-Lite Read Data Channel
  wire [AXI_DATA_WIDTH-1:0] s_axi_rdata;
  wire [               1:0] s_axi_rresp;
  wire                      s_axi_rvalid;
  reg                       s_axi_rready;

  // SRAM Interface
  wire [AXI_ADDR_WIDTH-1:0] sram_addr;
  wire [AXI_DATA_WIDTH-1:0] sram_data;
  wire                      sram_we_n;
  wire                      sram_oe_n;
  wire                      sram_ce_n;

  // Variable to store read data
  reg  [AXI_DATA_WIDTH-1:0] read_data;

  // Instantiate the AXI SRAM controller
  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl (
      .axi_aclk(axi_aclk),
      .axi_aresetn(axi_aresetn),
      .s_axi_awaddr(s_axi_awaddr),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),
      .s_axi_wdata(s_axi_wdata),
      .s_axi_wstrb(s_axi_wstrb),
      .s_axi_wvalid(s_axi_wvalid),
      .s_axi_wready(s_axi_wready),
      .s_axi_bresp(s_axi_bresp),
      .s_axi_bvalid(s_axi_bvalid),
      .s_axi_bready(s_axi_bready),
      .s_axi_araddr(s_axi_araddr),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),
      .s_axi_rdata(s_axi_rdata),
      .s_axi_rresp(s_axi_rresp),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rready(s_axi_rready),
      .sram_addr(sram_addr),
      .sram_data(sram_data),
      .sram_we_n(sram_we_n),
      .sram_oe_n(sram_oe_n),
      .sram_ce_n(sram_ce_n)
  );

  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram (
      .we_n(sram_we_n),
      .oe_n(sram_oe_n),
      .ce_n(sram_ce_n),
      .addr(sram_addr),
      .data_io(sram_data)
  );

  reg [8:0] test_line;

  // Clock generation
  initial begin
    axi_aclk = 0;
    forever #5 axi_aclk = ~axi_aclk;
  end

  `TEST_SETUP(axi_sram_controller_tb);


  task reset;
    begin
      s_axi_awaddr = 1'b0;
      s_axi_awvalid = 1'b0;
      s_axi_wdata = 1'b0;
      s_axi_wstrb = 1'b0;
      s_axi_wvalid = 1'b0;
      s_axi_bready = 1'b0;
      s_axi_araddr = 1'b0;
      s_axi_arvalid = 1'b0;
      read_data = 1'b0;

      axi_aresetn = 1'b0;
      @(posedge axi_aclk);

      axi_aresetn = 1'b1;
      @(posedge axi_aclk);
    end
  endtask


  task axi_write;
    input [AXI_ADDR_WIDTH-1:0] addr;
    input [AXI_DATA_WIDTH-1:0] data;

    begin
      // addr
      s_axi_awaddr  = addr;
      s_axi_awvalid = 1'b1;

      // data
      s_axi_wdata   = data;
      s_axi_wvalid  = 1'b1;

      // resp
      s_axi_bready  = 1'b1;

      // clock the input
      @(posedge axi_aclk);

      // We have to test the signals together because they can happen in the
      // same clock (and with the current implementation, they do.)
      `WAIT_FOR_SIGNAL(s_axi_awready && s_axi_wready);
      `ASSERT(s_axi_bvalid === 1'b1);
      `ASSERT(s_axi_bresp === 2'b00);

      s_axi_awvalid = 1'b0;
      s_axi_wvalid  = 1'b0;
      s_axi_bready  = 1'b0;
    end
  endtask


  task axi_read_expected;
    input [AXI_ADDR_WIDTH-1:0] addr;
    input [AXI_DATA_WIDTH-1:0] data;

    begin
      // setup the read
      s_axi_araddr  = addr;
      s_axi_arvalid = 1'b1;
      s_axi_rready  = 1'b1;

      // clock the input
      @(posedge axi_aclk);

      `WAIT_FOR_SIGNAL(s_axi_arready);

      // validate data
      `ASSERT(s_axi_rdata === data);

      // validate response
      `ASSERT(s_axi_rvalid === 1'b1);
      `ASSERT(s_axi_rresp === 2'b00);
    end
  endtask


  task test_waddr_only;
    begin
      test_line = `__LINE__;
      reset();

      s_axi_awaddr  = 10'hA0;
      s_axi_awvalid = 1'b1;

      // waddr should not go ready because the controller can't accept
      // another waddr until it receives a matching wdata.
      //
      // clock a few times for good measure
      repeat (10) begin
        @(posedge axi_aclk);
        `ASSERT(s_axi_awready === 1'b0);
      end
    end
  endtask


  task test_write;
    begin
      test_line = `__LINE__;
      reset();

      axi_write(10'hB0, 8'h10);
    end
  endtask


  task test_write_delay_resp;
    begin
      test_line = `__LINE__;
      reset();

      // setup the signals instead of calling axi_write so that we can
      // control (and test) the response ready
      s_axi_awaddr  = 10'hC0;
      s_axi_awvalid = 1'b1;
      s_axi_wdata   = 8'h20;
      s_axi_wvalid  = 1'b1;
      s_axi_bready  = 1'b0;
      @(posedge axi_aclk);

      `WAIT_FOR_SIGNAL(s_axi_awready && s_axi_wready);

      s_axi_awvalid = 1'b0;
      s_axi_wvalid  = 1'b0;

      // Our response should not be available
      `ASSERT(s_axi_bvalid === 1'b0);
      `ASSERT(s_axi_bresp !== 2'b00);

      // It should not be possible to write again because
      // we are blocked on the response
      s_axi_awaddr  = 10'hC1;
      s_axi_awvalid = 1'b1;
      s_axi_wdata   = 8'h21;
      s_axi_wvalid  = 1'b1;

      // Make sure a write can't start while blocked
      repeat (10) begin
        @(posedge axi_aclk);
        `ASSERT(s_axi_awready === 1'b0);
      end

      // Accept the response
      s_axi_bready = 1'b1;
      @(posedge axi_aclk);

      `ASSERT(s_axi_bvalid === 1'b1);
      `ASSERT(s_axi_bresp === 2'b00);
    end
  endtask


  task test_multi_write;
    begin
      test_line = `__LINE__;
      reset();

      axi_write(10'hD0, 8'h30);
      axi_write(10'hD1, 8'h31);
      axi_write(10'hD2, 8'h32);
    end
  endtask


  task test_read_write;
    begin
      test_line = `__LINE__;
      reset();

      axi_write(10'hE0, 8'h40);
      axi_read_expected(10'hE0, 8'h40);
    end
  endtask


  task test_read_write_multi;
    begin
      test_line = `__LINE__;
      reset();

      axi_write(10'hD0, 8'h50);
      axi_read_expected(10'hD0, 8'h50);

      axi_write(10'hD1, 8'h51);
      axi_read_expected(10'hD1, 8'h51);

      axi_write(10'hD2, 8'h52);
      axi_read_expected(10'hD2, 8'h52);
    end
  endtask


  task test_read_write_interleved;
    begin
      test_line = `__LINE__;
      reset();

      axi_write(10'hE0, 8'h50);
      axi_write(10'hE1, 8'h51);
      axi_write(10'hE2, 8'h52);

      axi_read_expected(10'hE0, 8'h50);
      axi_write(10'hE3, 8'h53);
      axi_read_expected(10'hE1, 8'h51);
      axi_write(10'hE4, 8'h54);
      axi_read_expected(10'hE2, 8'h52);
      axi_write(10'hE5, 8'h55);

      axi_read_expected(10'hE3, 8'h53);
      axi_read_expected(10'hE4, 8'h54);
      axi_read_expected(10'hE5, 8'h55);
    end
  endtask


  // Test sequence
  initial begin
    test_waddr_only();
    test_write();
    test_write_delay_resp();
    test_multi_write();

    test_read_write();
    test_read_write_multi();
    test_read_write_interleved();

    $finish;
  end
endmodule
