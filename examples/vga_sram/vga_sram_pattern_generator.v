`ifndef VGA_SRAM_PATTERN_GENERATOR_V
`define VGA_SRAM_PATTERN_GENERATOR_V

// TODO: double check for off by one errors on the boundary row/column
// boundaries.

// TODO: pass in vga screen size parameters

`include "directives.v"

module vga_sram_pattern_generator #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input  wire clk,
    input  wire reset,
    output reg  pattern_done,

    // SRAM AXI-Lite Write Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0] axi_awaddr,
    output reg                       axi_awvalid,
    input  wire                      axi_awready,

    // SRAM AXI-Lite Write Data Channel
    output reg  [        AXI_DATA_WIDTH-1:0] axi_wdata,
    // verilator lint_off UNDRIVEN
    output reg  [((AXI_DATA_WIDTH+7)/8)-1:0] axi_wstrb,
    // verilator lint_on UNDRIVEN
    output reg                               axi_wvalid,
    input  wire                              axi_wready,

    // SRAM AXI-Lite Write Response Channel
    //
    // TODO: do error checking
    // verilator lint_off UNUSEDSIGNAL
    //
    input  wire [1:0] axi_bresp,
    // verilator lint_on UNUSEDSIGNAL
    input  wire       axi_bvalid,
    output reg        axi_bready
);

  // The "state" management of this state machine is kinda overkill
  // but it's mentally convenient to have the style match the other
  // axi clients.

  // State definitions
  localparam IDLE = 1'b0;
  localparam WRITING = 1'b1;

  // State and next state registers
  reg                       state = IDLE;
  reg                       next_state;

  // Write controls
  reg                       write_start;
  wire                      write_done;

  // vga and mem positions
  reg  [               9:0] column;
  reg  [               9:0] row;
  wire [AXI_ADDR_WIDTH-1:0] addr;
  wire [AXI_DATA_WIDTH-1:0] data;

  reg                       done;

  // state machine
  always @(*) begin
    next_state  = state;
    write_start = 1'b0;

    if (!reset) begin
      case (state)
        IDLE: begin
          if (!done) begin
            write_start = 1'b1;
            next_state  = WRITING;
          end
        end

        WRITING: begin
          if (write_done) begin
            if (!done) begin
              write_start = 1'b1;
            end else begin
              next_state = IDLE;
            end
          end
        end
      endcase
    end
  end

  // state registration
  always @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  // row/column
  always @(posedge clk) begin
    if (reset) begin
      column <= 0;
      row    <= 0;
      done   <= 1'b0;
    end else begin
      if (write_done) begin
        if (column < 639) begin
          column <= column + 1;
        end else begin
          column <= 0;
          if (row < 479) begin
            row <= row + 1;
          end else begin
            done <= 1'b1;
          end
        end
      end
    end
  end

  //
  // AXI write
  //
  assign write_done = (axi_bready && axi_bvalid);

  always @(posedge clk) begin
    if (reset) begin
      axi_awvalid <= 1'b0;
      axi_wvalid  <= 1'b0;
      axi_bready  <= 1'b0;
    end else begin
      // We're always ready for a response
      axi_bready <= 1'b1;

      // kick off a write, or wait to de-assert valid
      if (write_start) begin
        axi_awaddr  <= addr;
        axi_wdata   <= data;
        axi_awvalid <= 1'b1;
        axi_wvalid  <= 1'b1;
      end else begin
        if (axi_awready && axi_awvalid) begin
          axi_awvalid <= 1'b0;
        end

        if (axi_wready && axi_wvalid) begin
          axi_wvalid <= 1'b0;
        end
      end
    end
  end

  assign addr = (row * 640) + column;

  assign data[15:12] = (row < 480 && column < 213) ? 4'b1111 : 4'b0000;
  assign data[11:8] = (row < 480 && column >= 213 && column < 426) ? 4'b1111 :
      4'b0000;
  assign data[7:4] = (row < 480 && column >= 426 && column < 640) ? 4'b1111 :
      4'b0000;
  assign data[3:0] = 4'b0000;

  // this is kinda hacky, but the idea is to not tell the caller
  // that we are done until the sram is done too.
  always @(posedge clk) begin
    if (reset) begin
      pattern_done <= 0;
    end else begin
      if (!pattern_done) begin
        pattern_done <= (done & write_done);
      end
    end
  end


endmodule

`endif
