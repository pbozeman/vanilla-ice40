`ifndef VGA_PIXEL_ITER_V
`define VGA_PIXEL_ITER_V

`include "directives.sv"

`include "iter.sv"
`include "vga_mode.sv"

module vga_pixel_iter #(
    parameter H_WHOLE_LINE  = `VGA_MODE_H_WHOLE_LINE,
    parameter V_WHOLE_FRAME = `VGA_MODE_V_WHOLE_FRAME,

    localparam X_BITS = $clog2(H_WHOLE_LINE),
    localparam Y_BITS = $clog2(V_WHOLE_FRAME)
) (
    input  logic              clk,
    input  logic              reset,
    input  logic              inc,
    output logic [X_BITS-1:0] x,
    output logic [Y_BITS-1:0] y,
    output logic              x_last,
    output logic              y_last
);
  // Using inc with the init might seem strange, but the reason is that we
  // init is similar to inc. The caller doesn't want values to change when
  // inc is low.
  iter #(
      .WIDTH(X_BITS)
  ) h_counter_i (
      .clk     (clk),
      .init    (reset || (x_last && inc)),
      .init_val('0),
      .max_val (X_BITS'(H_WHOLE_LINE - 1)),
      .inc     (inc),
      .val     (x),
      .last    (x_last)
  );

  iter #(
      .WIDTH(Y_BITS)
  ) v_counter_i (
      .clk     (clk),
      .init    (reset || (y_last && x_last && inc)),
      .init_val('0),
      .max_val (Y_BITS'(V_WHOLE_FRAME - 1)),
      .inc     (x_last && inc),
      .val     (y),
      .last    (y_last)
  );

endmodule

`endif
