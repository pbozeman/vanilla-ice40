`ifndef FB_ADDR_V
`define FB_ADDR_V

`include "directives.v"

`include "vga_mode.v"

module fb_addr #(
    parameter FB_WIDTH  = `VGA_MODE_H_VISIBLE,
    parameter FB_HEIGHT = `VGA_MODE_V_VISIBLE,
    parameter ADDR_BITS = 20
) (
    input  wire                 clk,
    input  wire [FB_X_BITS-1:0] x,
    input  wire [FB_Y_BITS-1:0] y,
    output reg  [ADDR_BITS-1:0] addr
);
  localparam FB_X_BITS = $clog2(FB_WIDTH);
  localparam FB_Y_BITS = $clog2(FB_HEIGHT);

  // Maybe come back and pipeline this later and add other features like
  // offsets and oob/clip detection.
  always @(posedge clk) begin
    addr <= (FB_WIDTH * y + x);
  end

endmodule

`endif
