`ifndef AXI_SRAM_CONTROLLER_V
`define AXI_SRAM_CONTROLLER_V

`include "directives.sv"
`include "sram_controller.sv"

// Note: wstrb is ignored as the boards with the sram chips
// I use have the ub and lb pins hard logicd to enable.
//
// TODO: come back and implement wstrb, and/or consider setting
// an error in the resp if they are used.
module axi_sram_controller #(
    parameter integer AXI_ADDR_WIDTH = 20,
    parameter integer AXI_DATA_WIDTH = 16
) (
    // AXI-Lite Global Signals
    input logic axi_clk,
    input logic axi_resetn,

    // AXI-Lite Write Address Channel
    input  logic [AXI_ADDR_WIDTH-1:0] axi_awaddr,
    input  logic                      axi_awvalid,
    output logic                      axi_awready,

    // AXI-Lite Write Data Channel
    input  logic [        AXI_DATA_WIDTH-1:0] axi_wdata,
    // verilator lint_off UNUSEDSIGNAL
    input  logic [((AXI_DATA_WIDTH+7)/8)-1:0] axi_wstrb,
    // verilator lint_on UNUSEDSIGNAL
    input  logic                              axi_wvalid,
    output logic                              axi_wready,

    // AXI-Lite Write Response Channel
    output logic [1:0] axi_bresp,
    output logic       axi_bvalid,
    input  logic       axi_bready,

    // AXI-Lite Read Address Channel
    input  logic [AXI_ADDR_WIDTH-1:0] axi_araddr,
    input  logic                      axi_arvalid,
    output logic                      axi_arready,

    // AXI-Lite Read Data Channel
    output logic [AXI_DATA_WIDTH-1:0] axi_rdata,
    output logic [               1:0] axi_rresp,
    output logic                      axi_rvalid,
    input  logic                      axi_rready,

    output logic [AXI_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire  [AXI_DATA_WIDTH-1:0] sram_io_data,
    output logic                      sram_io_we_n,
    output logic                      sram_io_oe_n,
    output logic                      sram_io_ce_n
);

  // SRAM signals
  logic                      sram_req;
  logic                      sram_write_enable;
  logic [AXI_ADDR_WIDTH-1:0] sram_addr_internal;
  logic [AXI_DATA_WIDTH-1:0] sram_write_data;
  logic                      sram_write_done;
  logic [AXI_DATA_WIDTH-1:0] sram_read_data;
  logic                      sram_read_data_valid;

  // verilator lint_off UNUSEDSIGNAL
  logic                      sram_ready;
  // verilator lint_on UNUSEDSIGNAL

  // FSM states (note: writes start with 0, reads with 1 in the msb)
  localparam IDLE = 3'b000;
  localparam WRITE = 3'b001;
  localparam WRITE_RESP = 3'b010;
  localparam READ = 3'b100;
  localparam READ_RESP = 3'b110;

  localparam RESP_OK = 2'b00;

  logic [2:0] current_state = IDLE;
  logic [2:0] next_state = IDLE;

  // write state
  logic       axi_bvalid_reg = 0;

  // read state
  logic       axi_rvalid_reg = 0;

  // Instantiate SRAM controller
  sram_controller #(
      .ADDR_BITS(AXI_ADDR_WIDTH),
      .DATA_BITS(AXI_DATA_WIDTH)
  ) sram_ctrl (
      .clk            (axi_clk),
      .reset          (~axi_resetn),
      .req            (sram_req),
      .ready          (sram_ready),
      .write_enable   (sram_write_enable),
      .addr           (sram_addr_internal),
      .write_data     (sram_write_data),
      .write_done     (sram_write_done),
      .read_data      (sram_read_data),
      .read_data_valid(sram_read_data_valid),
      .io_addr_bus    (sram_io_addr),
      .io_data_bus    (sram_io_data),
      .io_we_n        (sram_io_we_n),
      .io_oe_n        (sram_io_oe_n),
      .io_ce_n        (sram_io_ce_n)
  );

  // flip read/write priority every other cycle
  logic rw_pri = 0;
  always @(posedge axi_clk) begin
    if (sram_req) begin
      rw_pri <= ~rw_pri;
    end
  end

  // state machine
  always @(*) begin
    next_state = current_state;

    case (current_state)
      IDLE: begin
        // don't let readers/writers starve each other
        if (rw_pri) begin
          // prioritize writes
          if (axi_awvalid && axi_wvalid) begin
            next_state = WRITE;
          end else begin
            if (axi_arvalid) begin
              next_state = READ;
            end
          end
        end else begin
          // prioritize reads
          if (axi_arvalid) begin
            next_state = READ;
          end else begin
            if (axi_awvalid && axi_wvalid) begin
              next_state = WRITE;
            end
          end
        end
      end

      WRITE: begin
        if (sram_write_done & axi_bready) begin
          next_state = IDLE;
        end else begin
          next_state = WRITE_RESP;
        end
      end

      WRITE_RESP: begin
        if (axi_bready) begin
          next_state = IDLE;
        end else begin
          next_state = WRITE_RESP;
        end
      end

      READ: begin
        next_state = IDLE;

        if (axi_rready) begin
          next_state = IDLE;
        end else begin
          next_state = READ_RESP;
        end
      end

      READ_RESP: begin
        if (axi_rready) begin
          next_state = IDLE;
        end else begin
          next_state = READ_RESP;
        end
      end

      default: next_state = current_state;
    endcase
  end

  // state machine registration
  always @(posedge axi_clk) begin
    if (~axi_resetn) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  //
  // axi_bvalid
  //
  logic prev_axi_bready = 0;

  always @(posedge axi_clk) begin
    if (~axi_resetn) begin
      axi_bvalid_reg  <= 1'b0;
      prev_axi_bready <= 1'b0;
    end else begin
      prev_axi_bready <= axi_bready;
      if (sram_write_done) begin
        axi_bvalid_reg <= 1'b1;
      end else begin
        if ((axi_bready || prev_axi_bready) && axi_bvalid_reg) begin
          axi_bvalid_reg <= 1'b0;
        end
      end
    end
  end

  //
  // axi_rvalid
  //
  // Look for the rising edge of sram_read_data_valid and
  // register that so that we can clear axi_rvalid without
  // it getting reset by the sram controller.
  logic prev_sram_read_data_valid = 0;
  logic prev_axi_rready = 0;

  always @(posedge axi_clk) begin
    if (~axi_resetn) begin
      axi_rvalid_reg            <= 1'b0;
      prev_sram_read_data_valid <= 1'b0;
      prev_axi_rready           <= 1'b0;
    end else begin
      prev_sram_read_data_valid <= sram_read_data_valid;
      prev_axi_rready           <= axi_rready;

      if (!prev_sram_read_data_valid & sram_read_data_valid) begin
        axi_rvalid_reg <= sram_read_data_valid;
      end

      if ((axi_rready || prev_axi_rready) && axi_rvalid_reg) begin
        axi_rvalid_reg <= 1'b0;
      end
    end
  end

  // write channels
  assign axi_awready = (next_state == WRITE);
  assign axi_wready = (next_state == WRITE);
  assign axi_bvalid = axi_bvalid_reg;
  assign axi_bresp = (axi_bvalid ? RESP_OK : 2'bxx);

  // read channels
  assign axi_arready = (current_state == READ);
  assign axi_rvalid = axi_rvalid_reg;
  assign axi_rdata = (axi_rvalid ? sram_read_data : {AXI_DATA_WIDTH{1'bx}});
  assign axi_rresp = (axi_rvalid ? RESP_OK : 2'bxx);

  assign sram_write_enable = (next_state == WRITE);
  assign sram_addr_internal = (next_state == WRITE ? axi_awaddr : axi_araddr);
  assign sram_write_data = (next_state == WRITE ?
                            axi_wdata : {AXI_DATA_WIDTH{1'bx}});
  assign sram_req = (next_state == WRITE || next_state == READ);

endmodule

`endif
