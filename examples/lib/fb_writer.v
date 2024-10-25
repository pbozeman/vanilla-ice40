`ifndef FB_WRITER_V
`define FB_WRITER_V

`include "directives.v"

module fb_writer #(
    parameter PIXEL_BITS     = 12,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input wire clk,
    input wire reset,

    // axi stream handshake for the pixel
    input  wire axi_tvalid,
    output wire axi_tready,

    // pixel
    input wire [AXI_ADDR_WIDTH-1:0] addr,
    input wire [    PIXEL_BITS-1:0] color,

    //
    // The AXI interface backing the frame buffer.
    // This module is the master.
    //
    output reg  [        AXI_ADDR_WIDTH-1:0] sram_axi_awaddr,
    output reg                               sram_axi_awvalid,
    input  wire                              sram_axi_awready,
    output reg  [        AXI_DATA_WIDTH-1:0] sram_axi_wdata,
    output reg  [((AXI_DATA_WIDTH+7)/8)-1:0] sram_axi_wstrb,
    output reg                               sram_axi_wvalid,
    input  wire                              sram_axi_wready,
    output reg                               sram_axi_bready,
    // verilator lint_off UNUSEDSIGNAL
    input  wire                              sram_axi_bvalid,
    input  wire [                       1:0] sram_axi_bresp
    // verilator lint_on UNUSEDSIGNAL
);
  // State definitions
  localparam IDLE = 1'b0;
  localparam WRITING = 1'b1;

  // State and next state registers
  reg state = IDLE;
  reg next_state;

  reg write_start;

  // state machine
  always @(*) begin
    next_state  = state;
    write_start = 1'b0;

    case (state)
      IDLE: begin
        if (axi_tvalid) begin
          write_start = 1'b1;
          next_state  = WRITING;
        end
      end

      WRITING: begin
        if (sram_write_accepted) begin
          if (axi_tvalid) begin
            write_start = 1'b1;
            next_state  = WRITING;
          end else begin
            next_state = IDLE;
          end
        end
      end

      default: begin
      end
    endcase
  end

  // state registration
  always @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  //
  // AXI write
  //
  wire sram_write_addr_accepted = (sram_axi_awready & sram_axi_awvalid);
  wire sram_write_data_accepted = (sram_axi_wready & sram_axi_wvalid);
  wire sram_write_accepted = (sram_write_addr_accepted &
                              sram_write_data_accepted);

  always @(posedge clk) begin
    if (reset) begin
      sram_axi_awvalid <= 1'b0;
      sram_axi_wvalid  <= 1'b0;

      // We're always ready for a response
      sram_axi_bready  <= 1'b1;
    end else begin
      // kick off a write, or wait to de-assert valid
      if (write_start) begin
        sram_axi_awvalid <= 1'b1;
        sram_axi_wvalid  <= 1'b1;
      end else begin
        if (sram_axi_awready & sram_axi_awvalid) begin
          sram_axi_awvalid <= 1'b0;
        end

        if (sram_axi_wready & sram_axi_wvalid) begin
          sram_axi_wvalid <= 1'b0;
        end
      end
    end
  end

  // pulling these away from being dependent on reset provides better timing
  always @(posedge clk) begin
    if (write_start) begin
      sram_axi_awaddr <= addr;
      sram_axi_wdata  <= {color, {(AXI_DATA_WIDTH - PIXEL_BITS) {1'b0}}};
    end
  end

  assign axi_tready = (next_state == WRITING);

  // "unused" strobe signal
  always @(posedge clk) begin
    if (reset) begin
      sram_axi_wstrb <= {((AXI_DATA_WIDTH + 7) / 8) {1'b1}};
    end
  end
endmodule

`endif
