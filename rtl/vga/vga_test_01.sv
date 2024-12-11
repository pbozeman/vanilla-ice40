`ifndef VGA_TEST_01_V
`define VGA_TEST_01_V

`include "directives.sv"

`include "vga_mode.sv"

module vga_test_01 #(
    parameter H_VISIBLE    = 640,
    parameter H_WHOLE_LINE = 800,

    parameter V_VISIBLE     = 640,
    parameter V_WHOLE_FRAME = 525,

    localparam col_BITS = $clog2(H_WHOLE_LINE),
    localparam Y_BITS   = $clog2(V_WHOLE_FRAME),

    localparam THIRD_SCREEN = H_VISIBLE / 3,
    localparam RED_END      = THIRD_SCREEN,
    localparam GRN_START    = RED_END,
    localparam GRN_END      = THIRD_SCREEN * 2,
    localparam BLU_START    = GRN_END,
    localparam BLU_END      = H_VISIBLE

) (
    input        [col_BITS-1:0] x,
    input        [  Y_BITS-1:0] y,
    output logic [         3:0] green,
    output logic [         3:0] red,
    output logic [         3:0] blue
);
  assign red = (y < V_VISIBLE && x < RED_END) ? 4'b1111 : 4'b0000;
  assign green = ((y < V_VISIBLE && x >= GRN_START && x < GRN_END) ? 4'b1111 :
                  4'b0000);
  assign blue = ((y < V_VISIBLE && x >= BLU_START && x < BLU_END) ? 4'b1111 :
                 4'b0000);

endmodule

`endif
