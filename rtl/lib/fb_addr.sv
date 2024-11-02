`ifndef FB_ADDR_V
`define FB_ADDR_V

`include "directives.sv"

`include "vga_mode.sv"

module fb_addr #(
    parameter FB_WIDTH  = `VGA_MODE_H_VISIBLE,
    parameter FB_HEIGHT = `VGA_MODE_V_VISIBLE,
    parameter ADDR_BITS = 20
) (
    input  logic                 clk,
    input  logic [FB_X_BITS-1:0] x,
    input  logic [FB_Y_BITS-1:0] y,
    output logic [ADDR_BITS-1:0] addr
);
  localparam FB_X_BITS = $clog2(FB_WIDTH);
  localparam FB_Y_BITS = $clog2(FB_HEIGHT);

  // Maybe come back and pipeline this later and add other features like
  // offsets and oob/clip detection.
  always_ff @(posedge clk) begin
    addr <= (FB_WIDTH * y + x);
  end

endmodule

`endif
