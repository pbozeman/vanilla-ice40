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
  reg  [               3:0] s_axi_wstrb;
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

  // Clock generation
  initial begin
    axi_aclk = 0;
    forever #5 axi_aclk = ~axi_aclk;
  end

  `TEST_SETUP(axi_sram_controller_tb);


  task reset;
    begin
      s_axi_awaddr = 0;
      s_axi_awvalid = 0;
      s_axi_wdata = 0;
      s_axi_wstrb = 0;
      s_axi_wvalid = 0;
      s_axi_bready = 0;
      s_axi_araddr = 0;
      s_axi_arvalid = 0;
      read_data = 0;

      axi_aresetn = 0;
      @(posedge axi_aclk);

      axi_aresetn = 1;
      @(posedge axi_aclk);
    end
  endtask

  task test_waddr_only;
    begin
      reset();

      s_axi_awaddr  = 8'hA1;
      s_axi_awvalid = 1;

      // waddr should not go ready because the controller can't accept
      // another waddr until it receives a matching wdata.
      //
      // clock a few times for good measure
      repeat (10) begin
        `ASSERT(s_axi_awready === 1'b0);
        @(posedge axi_aclk);
      end
    end
  endtask

  // Test sequence
  initial begin
    test_waddr_only();

    $finish;
  end
endmodule
