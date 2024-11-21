`ifndef FB_WRITER_V
`define FB_WRITER_V

`include "directives.sv"

// This is mostly a direct pass through to an axi-lite writer. The goal here
// is to simply the interface so that the caller doesn't have to manage the
// addr and data lines and the response signaling. Dumb it all down so that
// it's easier to do basic operations.
module fb_writer #(
    parameter PIXEL_BITS,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16
) (
    // Because we are pure passthrough, we don't actually need to use the
    // clock. But, keep the signal, just in case we ever do.
    //
    // verilator lint_off UNUSEDSIGNAL
    input logic clk,
    input logic reset,
    // verilator lint_on UNUSEDSIGNAL

    // axi stream handshake for the pixel
    input  logic axi_tvalid,
    output logic axi_tready,

    // pixel
    input logic [AXI_ADDR_WIDTH-1:0] addr,
    input logic [    PIXEL_BITS-1:0] color,

    //
    // The AXI interface backing the frame buffer.
    // This module is the master.
    //
    output logic [        AXI_ADDR_WIDTH-1:0] sram_axi_awaddr,
    output logic                              sram_axi_awvalid,
    input  logic                              sram_axi_awready,
    output logic [        AXI_DATA_WIDTH-1:0] sram_axi_wdata,
    output logic [((AXI_DATA_WIDTH+7)/8)-1:0] sram_axi_wstrb,
    output logic                              sram_axi_wvalid,
    input  logic                              sram_axi_wready,
    output logic                              sram_axi_bready,
    // verilator lint_off UNUSEDSIGNAL
    input  logic                              sram_axi_bvalid,
    input  logic [                       1:0] sram_axi_bresp
    // verilator lint_on UNUSEDSIGNAL
);

  assign sram_axi_awvalid = axi_tvalid;
  assign sram_axi_awaddr  = addr;

  assign sram_axi_wvalid  = axi_tvalid;
  assign sram_axi_wdata   = {color, {(AXI_DATA_WIDTH - PIXEL_BITS) {1'b0}}};

  // We're always ready for a response...because we ignore it ¯\_(ツ)_/¯)
  assign sram_axi_bready  = 1'b1;
  assign sram_axi_wstrb   = {((AXI_DATA_WIDTH + 7) / 8) {1'b1}};

  assign axi_tready       = (sram_axi_awready & sram_axi_wready);

endmodule

`endif
