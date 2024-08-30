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

  task axi_write;
    input [AXI_ADDR_WIDTH-1:0] addr;
    input [AXI_DATA_WIDTH-1:0] data;
    begin
      // Wait for the device to be ready
      while (!s_axi_awready || !s_axi_wready) @(posedge axi_aclk);

      // Set address, data, and valid signals
      s_axi_awaddr  = addr;
      s_axi_wdata   = data;
      s_axi_wstrb   = 4'b1111;
      s_axi_awvalid = 1;
      s_axi_wvalid  = 1;
      s_axi_bready  = 1;

      // Wait for both address and data to be accepted
      @(posedge axi_aclk);

      // Clear valid signals
      s_axi_awvalid = 0;
      s_axi_wvalid  = 0;

      // Check SRAM signals during write operation
      `ASSERT(sram_addr === addr);
      `ASSERT(sram_data === data);
      `ASSERT(sram_we_n === 1'b0);

      // Wait for write response
      while (!s_axi_bvalid) @(posedge axi_aclk);
      `ASSERT(s_axi_bresp === 2'b00);

      s_axi_bready = 0;
    end
  endtask

  task axi_read;
    input [AXI_ADDR_WIDTH-1:0] addr;
    output [AXI_DATA_WIDTH-1:0] data;
    begin
      // Wait for the device to be ready
      while (!s_axi_arready) @(posedge axi_aclk);

      // Set address and valid signal
      s_axi_araddr  = addr;
      s_axi_arvalid = 1;
      s_axi_rready  = 1;

      // Wait for address to be accepted
      @(posedge axi_aclk);

      // Clear valid signal
      s_axi_arvalid = 0;

      // Check SRAM signals during read operation
      `ASSERT(sram_addr === addr);
      `ASSERT(sram_oe_n === 1'b0);

      // Wait for read data
      while (!s_axi_rvalid) @(posedge axi_aclk);
      `ASSERT(s_axi_rresp === 2'b00);

      s_axi_rready = 0;
      data = s_axi_rdata;
    end
  endtask

  // Test sequence
  initial begin
    // Initialize all inputs
    s_axi_awaddr = 0;
    s_axi_awvalid = 0;
    s_axi_wdata = 0;
    s_axi_wstrb = 0;
    s_axi_wvalid = 0;
    s_axi_bready = 0;
    s_axi_araddr = 0;
    s_axi_arvalid = 0;
    read_data = 0;

    // Reset
    axi_aresetn = 0;
    @(posedge axi_aclk);
    axi_aresetn = 1;
    @(posedge axi_aclk);

    // Single write
    axi_write(10'h0AA, 8'hA1);

    // Single read
    axi_read(10'h0AA, read_data);
    `ASSERT(read_data === 8'hA1)
    `ASSERT(sram_addr === 10'h0AA)

    // Wait for read operation to complete
    @(posedge axi_aclk);

    // Multi write
    axi_write(10'h101, 8'h51);
    axi_write(10'h102, 8'h52);
    axi_write(10'h103, 8'h53);

    // Multi read
    axi_read(10'h101, read_data);
    `ASSERT(read_data === 8'h51)
    `ASSERT(sram_addr === 10'h101)

    axi_read(10'h102, read_data);
    `ASSERT(read_data === 8'h52)
    `ASSERT(sram_addr === 10'h102)

    axi_read(10'h103, read_data);
    `ASSERT(read_data === 8'h53)
    `ASSERT(sram_addr === 10'h103)

    // Final check to ensure SRAM control signals are inactive
    @(posedge axi_aclk);
    `ASSERT(sram_we_n === 1'b1)
    `ASSERT(sram_oe_n === 1'b1)

    $finish;
  end
endmodule
