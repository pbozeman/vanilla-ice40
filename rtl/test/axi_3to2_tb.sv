`include "testing.sv"
`include "axi_3to2.sv"
`include "axi_sram_controller.sv"
`include "sram_model.sv"

// verilator lint_off UNUSEDSIGNAL
// verilator lint_off UNDRIVEN
module axi_3to2_tb;
  localparam AXI_ADDR_WIDTH = 20;
  localparam AXI_DATA_WIDTH = 16;
  localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH + 7) / 8;

  logic                      axi_clk;
  logic                      axi_resetn = 0;

  // Input 0 AXI interface
  logic [AXI_ADDR_WIDTH-1:0] in0_axi_awaddr;
  logic                      in0_axi_awvalid;
  logic                      in0_axi_awready;
  logic [AXI_DATA_WIDTH-1:0] in0_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] in0_axi_wstrb;
  logic                      in0_axi_wvalid;
  logic                      in0_axi_wready;
  logic [               1:0] in0_axi_bresp;
  logic                      in0_axi_bvalid;
  logic                      in0_axi_bready;
  logic [AXI_ADDR_WIDTH-1:0] in0_axi_araddr;
  logic                      in0_axi_arvalid;
  logic                      in0_axi_arready;
  logic [AXI_DATA_WIDTH-1:0] in0_axi_rdata;
  logic [               1:0] in0_axi_rresp;
  logic                      in0_axi_rvalid;
  logic                      in0_axi_rready;

  // Input 1 AXI interface
  logic [AXI_ADDR_WIDTH-1:0] in1_axi_awaddr;
  logic                      in1_axi_awvalid;
  logic                      in1_axi_awready;
  logic [AXI_DATA_WIDTH-1:0] in1_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] in1_axi_wstrb;
  logic                      in1_axi_wvalid;
  logic                      in1_axi_wready;
  logic [               1:0] in1_axi_bresp;
  logic                      in1_axi_bvalid;
  logic                      in1_axi_bready;
  logic [AXI_ADDR_WIDTH-1:0] in1_axi_araddr;
  logic                      in1_axi_arvalid;
  logic                      in1_axi_arready;
  logic [AXI_DATA_WIDTH-1:0] in1_axi_rdata;
  logic [               1:0] in1_axi_rresp;
  logic                      in1_axi_rvalid;
  logic                      in1_axi_rready;

  // Input 2 AXI interface
  logic [AXI_ADDR_WIDTH-1:0] in2_axi_awaddr;
  logic                      in2_axi_awvalid;
  logic                      in2_axi_awready;
  logic [AXI_DATA_WIDTH-1:0] in2_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] in2_axi_wstrb;
  logic                      in2_axi_wvalid;
  logic                      in2_axi_wready;
  logic [               1:0] in2_axi_bresp;
  logic                      in2_axi_bvalid;
  logic                      in2_axi_bready;
  logic [AXI_ADDR_WIDTH-1:0] in2_axi_araddr;
  logic                      in2_axi_arvalid;
  logic                      in2_axi_arready;
  logic [AXI_DATA_WIDTH-1:0] in2_axi_rdata;
  logic [               1:0] in2_axi_rresp;
  logic                      in2_axi_rvalid;
  logic                      in2_axi_rready;

  // Output 0 AXI interface
  logic [AXI_ADDR_WIDTH-1:0] out0_axi_awaddr;
  logic                      out0_axi_awvalid;
  logic                      out0_axi_awready;
  logic [AXI_DATA_WIDTH-1:0] out0_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] out0_axi_wstrb;
  logic                      out0_axi_wvalid;
  logic                      out0_axi_wready;
  logic [               1:0] out0_axi_bresp;
  logic                      out0_axi_bvalid;
  logic                      out0_axi_bready;
  logic [AXI_ADDR_WIDTH-1:0] out0_axi_araddr;
  logic                      out0_axi_arvalid;
  logic                      out0_axi_arready;
  logic [AXI_DATA_WIDTH-1:0] out0_axi_rdata;
  logic [               1:0] out0_axi_rresp;
  logic                      out0_axi_rvalid;
  logic                      out0_axi_rready;

  // Output 1 AXI interface
  logic [AXI_ADDR_WIDTH-1:0] out1_axi_awaddr;
  logic                      out1_axi_awvalid;
  logic                      out1_axi_awready;
  logic [AXI_DATA_WIDTH-1:0] out1_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] out1_axi_wstrb;
  logic                      out1_axi_wvalid;
  logic                      out1_axi_wready;
  logic [               1:0] out1_axi_bresp;
  logic                      out1_axi_bvalid;
  logic                      out1_axi_bready;
  logic [AXI_ADDR_WIDTH-1:0] out1_axi_araddr;
  logic                      out1_axi_arvalid;
  logic                      out1_axi_arready;
  logic [AXI_DATA_WIDTH-1:0] out1_axi_rdata;
  logic [               1:0] out1_axi_rresp;
  logic                      out1_axi_rvalid;
  logic                      out1_axi_rready;

  // SRAM 0
  logic [AXI_ADDR_WIDTH-1:0] sram0_io_addr;
  wire  [AXI_DATA_WIDTH-1:0] sram0_io_data;
  logic                      sram0_io_we_n;
  logic                      sram0_io_oe_n;
  logic                      sram0_io_ce_n;

  // SRAM 1
  logic [AXI_ADDR_WIDTH-1:0] sram1_io_addr;
  wire  [AXI_DATA_WIDTH-1:0] sram1_io_data;
  logic                      sram1_io_we_n;
  logic                      sram1_io_oe_n;
  logic                      sram1_io_ce_n;

  axi_3to2 #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) uut (
      .*
  );
  // It would be nice to have a unit test controllable test model for axi
  // devices, but for now, let's just use the axi sram controller to act as
  // the two out devices.
  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl_0 (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .axi_awaddr  (out0_axi_awaddr),
      .axi_awvalid (out0_axi_awvalid),
      .axi_awready (out0_axi_awready),
      .axi_wdata   (out0_axi_wdata),
      .axi_wstrb   (out0_axi_wstrb),
      .axi_wvalid  (out0_axi_wvalid),
      .axi_wready  (out0_axi_wready),
      .axi_bresp   (out0_axi_bresp),
      .axi_bvalid  (out0_axi_bvalid),
      .axi_bready  (out0_axi_bready),
      .axi_araddr  (out0_axi_araddr),
      .axi_arvalid (out0_axi_arvalid),
      .axi_arready (out0_axi_arready),
      .axi_rdata   (out0_axi_rdata),
      .axi_rresp   (out0_axi_rresp),
      .axi_rvalid  (out0_axi_rvalid),
      .axi_rready  (out0_axi_rready),
      .sram_io_addr(sram0_io_addr),
      .sram_io_data(sram0_io_data),
      .sram_io_we_n(sram0_io_we_n),
      .sram_io_oe_n(sram0_io_oe_n),
      .sram_io_ce_n(sram0_io_ce_n)
  );

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) ctrl_1 (
      .axi_clk     (axi_clk),
      .axi_resetn  (axi_resetn),
      .axi_awaddr  (out1_axi_awaddr),
      .axi_awvalid (out1_axi_awvalid),
      .axi_awready (out1_axi_awready),
      .axi_wdata   (out1_axi_wdata),
      .axi_wstrb   (out1_axi_wstrb),
      .axi_wvalid  (out1_axi_wvalid),
      .axi_wready  (out1_axi_wready),
      .axi_bresp   (out1_axi_bresp),
      .axi_bvalid  (out1_axi_bvalid),
      .axi_bready  (out1_axi_bready),
      .axi_araddr  (out1_axi_araddr),
      .axi_arvalid (out1_axi_arvalid),
      .axi_arready (out1_axi_arready),
      .axi_rdata   (out1_axi_rdata),
      .axi_rresp   (out1_axi_rresp),
      .axi_rvalid  (out1_axi_rvalid),
      .axi_rready  (out1_axi_rready),
      .sram_io_addr(sram1_io_addr),
      .sram_io_data(sram1_io_data),
      .sram_io_we_n(sram1_io_we_n),
      .sram_io_oe_n(sram1_io_oe_n),
      .sram_io_ce_n(sram1_io_ce_n)
  );

  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram_0 (
      .we_n   (sram0_io_we_n),
      .oe_n   (sram0_io_oe_n),
      .ce_n   (sram0_io_ce_n),
      .addr   (sram0_io_addr),
      .data_io(sram0_io_data)
  );

  sram_model #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram_1 (
      .we_n   (sram1_io_we_n),
      .oe_n   (sram1_io_oe_n),
      .ce_n   (sram1_io_ce_n),
      .addr   (sram1_io_addr),
      .data_io(sram1_io_data)
  );

  // verilator lint_off UNUSEDSIGNAL
  logic [8:0] test_line;
  // verilator lint_on UNUSEDSIGNAL

  // Clock generation
  initial begin
    axi_clk = 0;
    forever #5 axi_clk = ~axi_clk;
  end

  // Test setup
  `TEST_SETUP(axi_3to2_tb)

  task reset;
    begin
      @(posedge axi_clk);
      axi_resetn = 1'b0;
      @(posedge axi_clk);

      in0_axi_awaddr  = 0;
      in0_axi_awvalid = 0;
      in0_axi_wdata   = 0;
      in0_axi_wstrb   = 0;
      in0_axi_wvalid  = 0;
      in0_axi_bready  = 0;
      in0_axi_araddr  = 0;
      in0_axi_arvalid = 0;
      in0_axi_rready  = 0;

      in1_axi_awaddr  = 0;
      in1_axi_awvalid = 0;
      in1_axi_wdata   = 0;
      in1_axi_wstrb   = 0;
      in1_axi_wvalid  = 0;
      in1_axi_bready  = 0;
      in1_axi_araddr  = 0;
      in1_axi_arvalid = 0;
      in1_axi_rready  = 0;

      in2_axi_awaddr  = 0;
      in2_axi_awvalid = 0;
      in2_axi_wdata   = 0;
      in2_axi_wstrb   = 0;
      in2_axi_wvalid  = 0;
      in2_axi_bready  = 0;
      in2_axi_araddr  = 0;
      in2_axi_arvalid = 0;
      in2_axi_rready  = 0;

      @(posedge axi_clk);
      axi_resetn = 1'b1;
      @(posedge axi_clk);

      `ASSERT_EQ(uut.out0_grant, uut.CHANNEL_IDLE);
      `ASSERT_EQ(out0_axi_awaddr, '0);
      `ASSERT_EQ(out0_axi_awvalid, 1'b0);
      `ASSERT_EQ(out0_axi_wdata, '0);
      `ASSERT_EQ(out0_axi_wstrb, '0);
      `ASSERT_EQ(out0_axi_wvalid, 1'b0);
      `ASSERT_EQ(out0_axi_bready, 1'b0);
    end
  endtask

  //
  // auto clear write transactions
  //
  always @(posedge axi_clk) begin
    if (in0_axi_awvalid && in0_axi_awready) begin
      in0_axi_awvalid <= 0;
    end

    if (in0_axi_wvalid && in0_axi_wready) begin
      in0_axi_wvalid <= 0;
    end

    if (in1_axi_awvalid && in1_axi_awready) begin
      in1_axi_awvalid <= 0;
    end

    if (in1_axi_wvalid && in1_axi_wready) begin
      in1_axi_wvalid <= 0;
    end

    if (in2_axi_awvalid && in2_axi_awready) begin
      in2_axi_awvalid <= 0;
    end

    if (in2_axi_wvalid && in2_axi_wready) begin
      in2_axi_wvalid <= 0;
    end
  end

  //
  // auto clear read transactions
  //
  always @(posedge axi_clk) begin
    if (in0_axi_arvalid && in0_axi_arready) begin
      in0_axi_arvalid <= 0;
    end

    if (in1_axi_arvalid && in1_axi_arready) begin
      in1_axi_arvalid <= 0;
    end

    if (in2_axi_arvalid && in2_axi_arready) begin
      in2_axi_arvalid <= 0;
    end
  end

  task test_awaddr_grant_even;
    begin
      test_line = `__LINE__;
      reset();

      in0_axi_awaddr  = 20'hA000;
      in0_axi_awvalid = 1'b1;
      @(posedge axi_clk);
      @(negedge axi_clk);

      `ASSERT_EQ(uut.out0_grant, 0);
      `ASSERT_EQ(out0_axi_awvalid, 1'b1);
      `ASSERT_EQ(out0_axi_awaddr, 20'hA000);

      reset();
      in1_axi_awaddr  = 20'hB000;
      in1_axi_awvalid = 1'b1;
      @(posedge axi_clk);
      @(negedge axi_clk);

      `ASSERT_EQ(uut.out0_grant, 1);
      `ASSERT_EQ(out0_axi_awvalid, 1'b1);
      `ASSERT_EQ(out0_axi_awaddr, 20'hB000);

      reset();
      in2_axi_awaddr  = 20'hC000;
      in2_axi_awvalid = 1'b1;
      @(posedge axi_clk);
      @(negedge axi_clk);

      `ASSERT_EQ(uut.out0_grant, 2);
      `ASSERT_EQ(out0_axi_awvalid, 1'b1);
      `ASSERT_EQ(out0_axi_awaddr, 20'hC000);
    end
  endtask

  task test_awaddr_grant_even_pri;
    begin
      test_line = `__LINE__;
      reset();

      in0_axi_awaddr  = 20'hA000;
      in0_axi_awvalid = 1'b1;
      in1_axi_awaddr  = 20'hB000;
      in1_axi_awvalid = 1'b1;
      @(posedge axi_clk);
      @(negedge axi_clk);
      `ASSERT_EQ(uut.out0_grant, 0);
      `ASSERT_EQ(out0_axi_awvalid, 1'b1);
      `ASSERT_EQ(out0_axi_awaddr, 20'hA000);

      reset();

      in1_axi_awaddr  = 20'hB000;
      in1_axi_awvalid = 1'b1;
      in2_axi_awaddr  = 20'hC000;
      in2_axi_awvalid = 1'b1;
      @(posedge axi_clk);
      @(negedge axi_clk);
      `ASSERT_EQ(uut.out0_grant, 1);
      `ASSERT_EQ(out0_axi_awvalid, 1'b1);
      `ASSERT_EQ(out0_axi_awaddr, 20'hB000);
    end
  endtask

  task test_mux_even;
    begin
      test_line = `__LINE__;
      reset();

      in0_axi_awaddr  = 20'hA000;
      in0_axi_awvalid = 1'b1;
      in0_axi_wdata   = 16'hDEAD;
      in0_axi_wstrb   = 2'b10;
      in0_axi_wvalid  = 1'b0;
      in0_axi_bready  = 1'b1;
      @(posedge axi_clk);
      @(negedge axi_clk);

      `ASSERT_EQ(uut.out0_grant, 0);
      `ASSERT_EQ(out0_axi_awvalid, 1'b1);
      `ASSERT_EQ(out0_axi_awaddr, 20'hA000);
      `ASSERT_EQ(out0_axi_awvalid, 1'b1);
      `ASSERT_EQ(out0_axi_wdata, 16'hDEAD);
      `ASSERT_EQ(out0_axi_wstrb, 2'b10);
      `ASSERT_EQ(out0_axi_wvalid, 1'b0);
      `ASSERT_EQ(out0_axi_bready, 1'b1);
    end
  endtask

  initial begin
    test_awaddr_grant_even();
    test_awaddr_grant_even_pri();
    test_mux_even();

    #100;
    $finish;
  end
endmodule
// verilator lint_on UNUSEDSIGNAL
// verilator lint_on UNDRIVEN
