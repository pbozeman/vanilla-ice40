`ifndef AXI_SRAM_CONTROLLER_V
`define AXI_SRAM_CONTROLLER_V

`include "directives.v"
`include "sram_controller.v"

// Note: wstrb is ignored as the boards with the sram chips
// I use have the ub and lb pins hard wired to enable.
//
// TODO: come back and implement wstrb, and/or consider setting
// an error in the resp if they are used.
module axi_sram_controller #(
    parameter integer AXI_ADDR_WIDTH = 20,
    parameter integer AXI_DATA_WIDTH = 16
) (
    // AXI-Lite Global Signals
    input wire axi_clk,
    input wire axi_resetn,

    // AXI-Lite Write Address Channel
    input  wire [AXI_ADDR_WIDTH-1:0] axi_awaddr,
    input  wire                      axi_awvalid,
    output wire                      axi_awready,

    // AXI-Lite Write Data Channel
    input  wire [        AXI_DATA_WIDTH-1:0] axi_wdata,
    // verilator lint_off UNUSEDSIGNAL
    input  wire [((AXI_DATA_WIDTH+7)/8)-1:0] axi_wstrb,
    // verilator lint_on UNUSEDSIGNAL
    input  wire                              axi_wvalid,
    output wire                              axi_wready,

    // AXI-Lite Write Response Channel
    output wire [1:0] axi_bresp,
    output wire       axi_bvalid,
    input  wire       axi_bready,

    // AXI-Lite Read Address Channel
    input  wire [AXI_ADDR_WIDTH-1:0] axi_araddr,
    input  wire                      axi_arvalid,
    output wire                      axi_arready,

    // AXI-Lite Read Data Channel
    output wire [AXI_DATA_WIDTH-1:0] axi_rdata,
    output wire [               1:0] axi_rresp,
    output wire                      axi_rvalid,
    input  wire                      axi_rready,

    output wire [AXI_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire [AXI_DATA_WIDTH-1:0] sram_io_data,
    output wire                      sram_io_we_n,
    output wire                      sram_io_oe_n,
    output wire                      sram_io_ce_n
);

  // SRAM signals
  wire                      sram_req;
  wire                      sram_write_enable;
  wire [AXI_ADDR_WIDTH-1:0] sram_addr_internal;
  wire [AXI_DATA_WIDTH-1:0] sram_write_data;
  wire [AXI_DATA_WIDTH-1:0] sram_read_data;

  // TODO: if we used this we wouldn't need to make timing
  // assumptions
  // verilator lint_off UNUSEDSIGNAL
  wire                      sram_ready;
  // verilator lint_on UNUSEDSIGNAL

  // FSM states (note: writes start with 0, reads with 1 in the msb)
  localparam IDLE = 3'b000;
  localparam WRITE = 3'b001;
  localparam WRITE_RESP = 3'b010;
  localparam READ = 3'b100;
  localparam READ_RESP = 3'b110;

  localparam RESP_OK = 2'b00;

  reg [2:0] current_state = IDLE;
  reg [2:0] next_state = IDLE;

  // write state
  reg       writing;
  reg       write_done;
  reg       write_resp_valid;

  // read state
  reg       reading;
  reg       read_done;
  reg       read_resp_valid;

  // Instantiate SRAM controller
  sram_controller #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram_ctrl (
      .clk         (axi_clk),
      .reset       (~axi_resetn),
      .req         (sram_req),
      .ready       (sram_ready),
      .write_enable(sram_write_enable),
      .addr        (sram_addr_internal),
      .write_data  (sram_write_data),
      .read_data   (sram_read_data),
      .io_addr_bus (sram_io_addr),
      .io_data_bus (sram_io_data),
      .io_we_n     (sram_io_we_n),
      .io_oe_n     (sram_io_oe_n),
      .io_ce_n     (sram_io_ce_n)
  );

  // state machine
  always @(*) begin
    next_state       = current_state;

    writing          = 1'b0;
    write_done       = 1'b0;
    write_resp_valid = 1'b0;

    reading          = 1'b0;
    read_done        = 1'b0;
    read_resp_valid  = 1'b0;

    case (current_state)
      IDLE: begin
        if (axi_awvalid && axi_wvalid) begin
          next_state = WRITE;
          writing    = 1'b1;
        end else begin
          if (axi_arvalid) begin
            next_state = READ;
            reading    = 1'b1;
          end
        end
      end

      WRITE: begin
        writing    = 1'b1;
        write_done = 1'b1;

        if (axi_bready & sram_io_we_n) begin
          write_resp_valid = 1'b1;
          next_state       = IDLE;
        end else begin
          next_state = WRITE_RESP;
        end
      end

      WRITE_RESP: begin
        if (axi_bready) begin
          write_resp_valid = 1'b1;
          next_state       = IDLE;
        end else begin
          next_state = WRITE_RESP;
        end
      end

      READ: begin
        reading    = 1'b1;
        read_done  = 1'b1;
        next_state = IDLE;

        if (axi_rready) begin
          read_resp_valid = 1'b1;
          next_state      = IDLE;
        end else begin
          next_state = READ_RESP;
        end
      end

      READ_RESP: begin
        if (axi_rready) begin
          read_resp_valid = 1'b1;
          next_state      = IDLE;
        end else begin
          next_state = READ_RESP;
        end
      end

      default: next_state = current_state;
    endcase
  end

  // state machine registration
  always @(posedge axi_clk or negedge axi_resetn) begin
    if (~axi_resetn) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  // write channels
  assign axi_awready = write_done;
  assign axi_wready = write_done;
  assign axi_bvalid = write_resp_valid;
  assign axi_bresp = (write_resp_valid ? RESP_OK : 2'bxx);

  // read channels
  assign axi_arready = read_done;
  assign axi_rdata = (reading ? sram_read_data : {AXI_DATA_WIDTH{1'bx}});
  assign axi_rvalid = read_resp_valid;
  assign axi_rresp = (read_resp_valid ? RESP_OK : 2'bxx);

  assign sram_write_enable = writing;
  assign sram_addr_internal = (writing ? axi_awaddr : axi_araddr);
  assign sram_write_data = (writing ? axi_wdata : {AXI_DATA_WIDTH{1'bx}});
  assign sram_req = (writing || reading);

endmodule

`endif
