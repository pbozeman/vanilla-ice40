`ifndef VGA_SRAM_PATTERN_GENERATOR_V
`define VGA_SRAM_PATTERN_GENERATOR_V

// TODO: double check for off by one errors on the boundary row/column
// boundaries.

`include "directives.v"

module vga_sram_pattern_generator #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    input  wire clk,
    input  wire reset,
    output wire pattern_done,

    // SRAM AXI-Lite Write Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    output reg                       s_axi_awvalid,
    input  wire                      s_axi_awready,

    // SRAM AXI-Lite Write Data Channel
    output reg  [        AXI_DATA_WIDTH-1:0] s_axi_wdata,
    output reg  [((AXI_DATA_WIDTH+7)/8)-1:0] s_axi_wstrb,
    output reg                               s_axi_wvalid,
    input  wire                              s_axi_wready,

    // SRAM AXI-Lite Write Response Channel
    input  wire [1:0] s_axi_bresp,
    input  wire       s_axi_bvalid,
    output reg        s_axi_bready
);

  // The "state" management of this state machine is kinda overkill
  // but it's mentally convenient to have the style match the other
  // axi clients.

  // State definitions
  localparam IDLE = 1'b0;
  localparam WRITING = 1'b1;

  // State and next state registers
  reg state = IDLE;
  reg next_state;

  // Write controls
  reg write_start;
  wire write_done;

  // vga and mem positions
  reg [9:0] column = 0;
  reg [9:0] row = 0;
  wire [AXI_ADDR_WIDTH-1:0] addr;
  wire [AXI_DATA_WIDTH-1:0] data;

  assign pattern_done = (row == 479 && column == 639);

  // state machine
  always @(*) begin
    next_state  = state;
    write_start = 1'b0;

    if (!reset) begin
      case (state)
        IDLE: begin
          if (!pattern_done) begin
            write_start = 1'b1;
            next_state  = WRITING;
          end
        end

        WRITING: begin
          if (write_done) begin
            if (!pattern_done) begin
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
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  // row/column
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      column <= 0;
      row <= 0;
    end else begin
      if (!pattern_done) begin
        if (write_done) begin
          if (column < 640) begin
            column <= column + 1;
          end else begin
            column <= 0;
            row <= row + 1;
          end
        end
      end
    end
  end

  //
  // AXI write
  //
  assign write_done = (s_axi_bready && s_axi_bvalid);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      s_axi_awvalid <= 1'b0;
      s_axi_wvalid  <= 1'b0;
      s_axi_bready  <= 1'b0;
    end else begin
      // We're always ready for a response
      s_axi_bready <= 1'b1;

      // kick off a write, or wait to de-assert valid
      if (write_start) begin
        s_axi_awaddr  <= addr;
        s_axi_wdata   <= data;
        s_axi_awvalid <= 1'b1;
        s_axi_wvalid  <= 1'b1;
      end else begin
        if (s_axi_awready && s_axi_awvalid) begin
          s_axi_awvalid <= 1'b0;
        end

        if (s_axi_wready && s_axi_wvalid) begin
          s_axi_wvalid <= 1'b0;
        end
      end
    end
  end

  assign addr = (row * 640) + column;

  assign data[15:12] = (row < 480 && column < 213) ? column : 4'b0000;
  assign data[11:8] = (row < 480 && column >= 213 && column < 426) ? column : 4'b0000;
  assign data[7:4] = (row < 480 && column >= 426 && column < 640) ? column : 4'b0000;
  // assign data[15:12] = (row < 480 && column < 213) ? 4'b1111 : 4'b0000;
  // assign data[11:8] = (row < 480 && column >= 213 && column < 426) ? 4'b1111 : 4'b0000;
  // assign data[7:4] = (row < 480 && column >= 426 && column < 640) ? 4'b1111 : 4'b0000;
  assign data[3:0] = 4'b0000;

endmodule

`endif
