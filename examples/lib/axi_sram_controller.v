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

    // SRAM Interface
    output wire [AXI_ADDR_WIDTH-1:0] sram_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram_data,
    output wire                      sram_we_n,
    output wire                      sram_oe_n,
    output wire                      sram_ce_n
);

  // Internal signals
  wire                      sram_req;
  wire                      sram_write_enable;
  reg  [AXI_ADDR_WIDTH-1:0] sram_addr_internal = 0;
  reg  [AXI_DATA_WIDTH-1:0] sram_write_data = 0;
  wire [AXI_DATA_WIDTH-1:0] sram_read_data;
  wire                      sram_ready;

  // AXI-Lite FSM states
  localparam IDLE = 2'd0;
  localparam READ = 2'd1;
  localparam WRITE = 2'd2;
  localparam RESP = 2'd3;

  localparam RESP_OK = 2'b00;

  reg [1:0] axi_state = IDLE;
  reg [1:0] axi_next_state;

  reg sram_req_reg;

  // AXI-Lite control signals
  reg s_axi_bvalid_reg = 0;
  reg s_axi_rvalid_reg = 0;
  reg [AXI_DATA_WIDTH-1:0] s_axi_rdata_reg = 0;

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

  // AXI-Lite state machine
  always @(*) begin
    axi_next_state = axi_state;

    case (axi_state)
      IDLE: begin
        if (s_axi_awvalid && s_axi_wvalid) begin
          axi_next_state = WRITE;
        end else if (s_axi_arvalid) begin
          axi_next_state = READ;
        end
      end
      READ: begin
        if (sram_ready && s_axi_rready) begin
          axi_next_state = IDLE;
        end
      end
      WRITE: begin
        if (sram_ready) begin
          if (s_axi_bready) begin
            axi_next_state = IDLE;
          end else begin
            axi_next_state = RESP;
          end
        end
      end
      RESP: begin
        if (s_axi_bready) begin
          axi_next_state = IDLE;
        end
      end
    endcase
  end

  // AXI-Lite control logic
  always @(posedge axi_aclk or posedge ~axi_aresetn) begin
    if (~axi_aresetn) begin
      axi_state <= IDLE;
      s_axi_bvalid_reg <= 0;
      s_axi_rvalid_reg <= 0;
      s_axi_rdata_reg <= 0;
      sram_addr_internal <= 0;
      sram_write_data <= 0;
    end else begin
      axi_state <= axi_next_state;
      sram_req_reg <= 1'b0;

      case (axi_state)
        IDLE: begin
          s_axi_bvalid_reg <= 0;
          s_axi_rvalid_reg <= 0;

          if (s_axi_arvalid) begin
            sram_req_reg <= 1'b1;
            sram_addr_internal <= s_axi_araddr[AXI_ADDR_WIDTH-1:0];
          end else if (s_axi_awvalid && s_axi_wvalid) begin
            sram_req_reg <= 1'b1;
            sram_addr_internal <= s_axi_awaddr[AXI_ADDR_WIDTH-1:0];
            sram_write_data <= s_axi_wdata[AXI_DATA_WIDTH-1:0];
          end
        end
        READ: begin
          if (sram_ready) begin
            s_axi_rdata_reg  <= {{(AXI_DATA_WIDTH - AXI_DATA_WIDTH) {1'b0}}, sram_read_data};
            s_axi_rvalid_reg <= 1;
          end
          if (s_axi_rready && s_axi_rvalid_reg) begin
            s_axi_rvalid_reg <= 0;
          end
        end
        WRITE: begin
          if (sram_ready) begin
            s_axi_bvalid_reg <= 1;
          end
        end
        RESP: begin
          if (s_axi_bready) begin
            s_axi_bvalid_reg <= 0;
          end
        end
      endcase
    end
  end

  // read channel
  assign s_axi_arready = sram_ready;
  assign s_axi_rvalid = s_axi_rvalid_reg;
  assign s_axi_rdata = s_axi_rdata_reg;
  assign s_axi_rresp = RESP_OK;

  // write channel
  assign s_axi_awready = sram_ready;
  assign s_axi_wready = sram_ready;
  assign s_axi_bvalid = s_axi_bvalid_reg;
  assign s_axi_bresp = RESP_OK;

  assign sram_req = sram_req_reg;
  assign sram_write_enable = (axi_next_state == WRITE || axi_state == WRITE);

endmodule

`endif
