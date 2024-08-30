`ifndef AXI_SRAM_CONTROLLER_V
`define AXI_SRAM_CONTROLLER_V

`include "directives.v"
`include "sram_controller.v"

module axi_sram_controller #(
    parameter integer AXI_ADDR_WIDTH = 20,
    parameter integer AXI_DATA_WIDTH = 16
) (
    // AXI-Lite Global Signals
    input wire axi_aclk,
    input wire axi_aresetn,

    // AXI-Lite Write Address Channel
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,

    // AXI-Lite Write Data Channel
    input  wire [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [               3:0] s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output wire                      s_axi_wready,

    // AXI-Lite Write Response Channel
    output wire [1:0] s_axi_bresp,
    output wire       s_axi_bvalid,
    input  wire       s_axi_bready,

    // AXI-Lite Read Address Channel
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output wire                      s_axi_arready,

    // AXI-Lite Read Data Channel
    output wire [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output wire [               1:0] s_axi_rresp,
    output wire                      s_axi_rvalid,
    input  wire                      s_axi_rready,

    // TODO: rename sram_addr and data to *_bus
    // SRAM Interface
    output wire [AXI_ADDR_WIDTH-1:0] sram_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram_data,
    output wire                      sram_we_n,
    output wire                      sram_oe_n,
    output wire                      sram_ce_n
);

  // SRAM signals
  wire                      sram_req;
  wire                      sram_write_enable;
  reg  [AXI_ADDR_WIDTH-1:0] sram_addr_internal = 0;
  reg  [AXI_DATA_WIDTH-1:0] sram_write_data = 0;
  wire [AXI_DATA_WIDTH-1:0] sram_read_data;
  wire                      sram_ready;

  // FSM states
  localparam IDLE = 2'd0;

  localparam RESP_OK = 2'b00;

  reg [1:0] current_state = IDLE;
  reg [1:0] next_state = IDLE;

  // write state
  reg [AXI_ADDR_WIDTH-1:0] write_addr;
  reg write_addr_valid;
  reg write_accepted;

  // Instantiate SRAM controller
  sram_controller #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram_ctrl (
      .clk(axi_aclk),
      .reset(~axi_aresetn),
      .req(sram_req),
      .ready(sram_ready),
      .write_enable(sram_write_enable),
      .addr(sram_addr_internal),
      .write_data(sram_write_data),
      .read_data(sram_read_data),
      .addr_bus(sram_addr),
      .data_bus_io(sram_data),
      .we_n(sram_we_n),
      .oe_n(sram_oe_n),
      .ce_n(sram_ce_n)
  );


  // state machine
  always @(*) begin
    // TODO: flesh out
    case (current_state)
      default: next_state = current_state;
    endcase
  end

  // state registration
  always @(posedge axi_aclk or negedge axi_aresetn) begin
    if (~axi_aresetn) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  // write state
  always @(posedge axi_aclk or negedge axi_aresetn) begin
    if (~axi_aresetn) begin
      write_addr <= {AXI_ADDR_WIDTH{1'bx}};
      write_addr_valid <= 1'b0;
      write_accepted <= 1'b0;
    end else begin
      if (s_axi_awvalid) begin
        write_addr <= s_axi_awaddr;
        write_addr_valid <= 1'b1;
      end
    end
  end

  assign s_axi_awready = write_accepted;

endmodule

`endif
