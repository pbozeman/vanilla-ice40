`include "testing.sv"
`include "axi_sram_controller.sv"
`include "sram_model.sv"

module axi_sram_controller_tb;
  localparam AXI_ADDR_WIDTH = 10;
  localparam AXI_DATA_WIDTH = 8;

  logic                      axi_clk;
  logic                      axi_resetn;

  // AXI-Lite Write Address Channel
  logic [AXI_ADDR_WIDTH-1:0] axi_awaddr;
  logic                      axi_awvalid;
  logic                      axi_awready;

  // AXI-Lite Write Data Channel
  logic [AXI_DATA_WIDTH-1:0] axi_wdata;
  logic                      axi_wstrb;
  logic                      axi_wvalid;
  logic                      axi_wready;

  // AXI-Lite Write Response Channel
  logic [               1:0] axi_bresp;
  logic                      axi_bvalid;
  logic                      axi_bready;

  // AXI-Lite Read Address Channel
  logic [AXI_ADDR_WIDTH-1:0] axi_araddr;
  logic                      axi_arvalid;
  logic                      axi_arready;

  // AXI-Lite Read Data Channel
  logic [AXI_DATA_WIDTH-1:0] axi_rdata;
  logic [               1:0] axi_rresp;
  logic                      axi_rvalid;
  logic                      axi_rready;

  // SRAM Interface
  logic [AXI_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [AXI_DATA_WIDTH-1:0] sram_io_data;
  logic                      sram_io_we_n;
  logic                      sram_io_oe_n;
  logic                      sram_io_ce_n;

  // Instantiate the AXI SRAM controller
  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .axi_awaddr  (axi_awaddr),
      .axi_awvalid (axi_awvalid),
      .axi_awready (axi_awready),
      .axi_wdata   (axi_wdata),
      .axi_wstrb   (axi_wstrb),
      .axi_wvalid  (axi_wvalid),
      .axi_wready  (axi_wready),
      .axi_bresp   (axi_bresp),
      .axi_bvalid  (axi_bvalid),
      .axi_bready  (axi_bready),
      .axi_araddr  (axi_araddr),
      .axi_arvalid (axi_arvalid),
      .axi_arready (axi_arready),
      .axi_rdata   (axi_rdata),
      .axi_rresp   (axi_rresp),
      .axi_rvalid  (axi_rvalid),
      .axi_rready  (axi_rready),
      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  // Instantiate the mocked SRAM model
  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram (
      .we_n   (sram_io_we_n),
      .oe_n   (sram_io_oe_n),
      .ce_n   (sram_io_ce_n),
      .addr   (sram_io_addr),
      .data_io(sram_io_data)
  );

  // verilator lint_off UNUSEDSIGNAL
  logic [8:0] test_line;
  // verilator lint_on UNUSEDSIGNAL

  // Clock generation
  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  `TEST_SETUP(axi_sram_controller_tb);

  always @(posedge axi_clk) begin
    if (axi_arvalid & axi_arready) begin
      axi_arvalid <= 1'b0;
    end
  end

  always @(posedge axi_clk) begin
    if (axi_awvalid & axi_awready) begin
      axi_awvalid <= 1'b0;
    end
  end

  always @(posedge axi_clk) begin
    if (axi_wvalid & axi_wready) begin
      axi_wvalid <= 1'b0;
    end
  end

  task reset;
    begin
      axi_awaddr  = '0;
      axi_awvalid = 1'b0;
      axi_wdata   = '0;
      axi_wstrb   = '0;
      axi_wvalid  = 1'b0;
      axi_bready  = 1'b0;
      axi_araddr  = '0;
      axi_arvalid = 1'b0;

      axi_resetn  = 1'b0;
      @(posedge axi_clk);
      @(negedge axi_clk);

      axi_resetn = 1'b1;
      @(posedge axi_clk);
    end
  endtask


  task axi_write;
    input [AXI_ADDR_WIDTH-1:0] addr;
    input [AXI_DATA_WIDTH-1:0] data;

    begin
      // addr
      axi_awaddr  = addr;
      axi_awvalid = 1'b1;

      // data
      axi_wdata   = data;
      axi_wvalid  = 1'b1;

      // resp
      axi_bready  = 1'b1;

      // clock the input
      @(posedge axi_clk);

      `WAIT_FOR_SIGNAL(axi_bvalid);
      `ASSERT(axi_bresp === 2'b00);

      axi_bready = 1'b0;
    end
  endtask

  task axi_write_fast;
    input [AXI_ADDR_WIDTH-1:0] addr;
    input [AXI_DATA_WIDTH-1:0] data;

    begin
      // addr
      axi_awaddr  = addr;
      axi_awvalid = 1'b1;

      // data
      axi_wdata   = data;
      axi_wvalid  = 1'b1;

      // resp
      axi_bready  = 1'b1;

      `WAIT_FOR_SIGNAL(axi_awready);
      @(posedge axi_clk);
    end
  endtask


  task axi_read_expected;
    input [AXI_ADDR_WIDTH-1:0] addr;
    input [AXI_DATA_WIDTH-1:0] data;

    begin
      // setup the read
      axi_araddr  = addr;
      axi_arvalid = 1'b1;
      axi_rready  = 1'b1;

      // clock the input
      @(posedge axi_clk);

      `WAIT_FOR_SIGNAL(axi_arready);
      `WAIT_FOR_SIGNAL(axi_rvalid);

      // validate data
      `ASSERT(axi_rdata === data);

      // validate response
      `ASSERT(axi_rresp === 2'b00);
    end
  endtask


  task test_waddr_only;
    begin
      test_line = `__LINE__;
      reset();

      axi_awaddr  = 10'hA0;
      axi_awvalid = 1'b1;

      // waddr should not go ready because the controller can't accept
      // another waddr until it receives a matching wdata.
      //
      // clock a few times for good measure
      repeat (10) begin
        @(posedge axi_clk);
        `ASSERT(axi_awready === 1'b0);
      end
    end
  endtask


  task test_write;
    begin
      test_line = `__LINE__;
      reset();

      axi_write(10'hB0, 8'h10);
      #100;
    end
  endtask


  task test_write_delay_resp;
    begin
      test_line = `__LINE__;
      reset();

      // setup the signals instead of calling axi_write so that we can
      // control (and test) the response ready
      axi_awaddr  = 10'hC0;
      axi_awvalid = 1'b1;
      axi_wdata   = 8'h20;
      axi_wvalid  = 1'b1;
      axi_bready  = 1'b0;
      @(posedge axi_clk);

      `WAIT_FOR_SIGNAL(axi_awready && axi_wready);

      // It should not be possible to write again because
      // we are blocked on the response
      axi_awaddr  = 10'hC1;
      axi_awvalid = 1'b1;
      axi_wdata   = 8'h21;
      axi_wvalid  = 1'b1;

      // Make sure a write can't start while blocked
      repeat (10) begin
        @(posedge axi_clk);
        `ASSERT(axi_awready === 1'b0);
      end

      `ASSERT(axi_bvalid === 1'b1);
      `ASSERT(axi_bresp === 2'b00);

      // Accept the response
      axi_bready = 1'b1;
      @(posedge axi_clk);
      @(negedge axi_clk);

      `ASSERT(axi_bvalid === 1'b0);
      `ASSERT(axi_bresp === 2'bxx);
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

  task test_multi_write_fast;
    begin
      test_line = `__LINE__;
      reset();

      axi_write_fast(10'hD0, 8'h30);
      axi_write_fast(10'hD1, 8'h31);
      axi_write_fast(10'hD2, 8'h32);

      #100;
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


  task test_read_delay_resp;
    begin
      test_line = `__LINE__;
      reset();

      axi_write(10'hF0, 8'h60);

      // setup the read
      axi_araddr  = 10'hF0;
      axi_arvalid = 1'b1;
      axi_rready  = 1'b0;

      // clock the input
      @(posedge axi_clk);

      // Our response should not be available
      `ASSERT(axi_rdata === 8'bxx);
      `ASSERT(axi_rvalid === 1'b0);
      `ASSERT(axi_rresp === 2'bxx);

      `WAIT_FOR_SIGNAL(axi_rvalid);

      `ASSERT(axi_rresp === 2'b00);
      `ASSERT(axi_rdata === 8'h60);

      // It should not be possible to read again because
      // we are blocked on a response
      axi_araddr  = 10'hF0;
      axi_arvalid = 1'b1;

      // Make sure a read can't start a while blocked
      repeat (10) begin
        @(posedge axi_clk);
        `ASSERT(axi_arready === 1'b0);
      end

      `ASSERT(axi_rvalid);
      `ASSERT(axi_rresp === 2'b00);
      `ASSERT(axi_rdata === 8'h60);

      // Similarly, we should not be able to write
      axi_awaddr  = 10'hF1;
      axi_awvalid = 1'b1;
      axi_wdata   = 8'h61;
      axi_wvalid  = 1'b1;
      axi_bready  = 1'b1;

      // Make sure a write can't start while blocked
      repeat (10) begin
        @(posedge axi_clk);
        `ASSERT(axi_awready === 1'b0);
      end

      // Accept the response
      axi_rready = 1'b1;
      @(posedge axi_clk);
      @(negedge axi_clk);
      `ASSERT(!axi_rvalid);

      // allow it to go to the next txn
      @(posedge axi_clk);

      // Then the read should clear
      `WAIT_FOR_SIGNAL(axi_rvalid);

      // validate the write went through (and that we can read
      // after all these shenanigans)
      axi_read_expected(10'hF1, 8'h61);
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
    test_read_delay_resp();

    test_multi_write_fast();
    #100;

    $finish;
  end
endmodule
