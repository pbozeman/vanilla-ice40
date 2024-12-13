`ifndef TLIGHT_V
`define TLIGHT_V

`include "directives.sv"

`ifdef VGA_MODE_640_480_60
`include "vga_mode.sv"
`include "vga_sync.sv"

module tlight #(
    parameter PIXEL_BITS = 12,

    parameter H_VISIBLE     = `VGA_MODE_H_VISIBLE,
    parameter H_FRONT_PORCH = `VGA_MODE_H_FRONT_PORCH,
    parameter H_SYNC_PULSE  = `VGA_MODE_H_SYNC_PULSE,
    parameter H_BACK_PORCH  = `VGA_MODE_H_BACK_PORCH,
    parameter H_WHOLE_LINE  = `VGA_MODE_H_WHOLE_LINE,

    parameter V_VISIBLE     = `VGA_MODE_V_VISIBLE,
    parameter V_FRONT_PORCH = `VGA_MODE_V_FRONT_PORCH,
    parameter V_SYNC_PULSE  = `VGA_MODE_V_SYNC_PULSE,
    parameter V_BACK_PORCH  = `VGA_MODE_V_BACK_PORCH,
    parameter V_WHOLE_FRAME = `VGA_MODE_V_WHOLE_FRAME,

    localparam COLOR_BITS = PIXEL_BITS / 3
) (
    input logic clk,
    input logic reset,

    // vga signals
    output logic [COLOR_BITS-1:0] vga_red,
    output logic [COLOR_BITS-1:0] vga_grn,
    output logic [COLOR_BITS-1:0] vga_blu,
    output logic                  vga_hsync,
    output logic                  vga_vsync

);
  // quick hack to get the clock rate into this module.
  // Normally VGA_MODE_TB_PIXEL_CLK is only used in simulation.
  localparam CLK_FREQ_HZ = `VGA_MODE_TB_PIXEL_CLK * 1_000_000;

  // Number of seconds to stay on a color
  localparam COLOR_DURATION_SEC = 4;

  // Number of clocks to stay on a color
  localparam HOLD_MAX = CLK_FREQ_HZ / COLOR_DURATION_SEC;

  // Pixel colors to display
  // We will start with 0, so, the order needs to be R/Y/G
  logic [                 2:0][PIXEL_BITS-1:0] colors;

  //
  // color hold and mux sel signals
  //
  logic [$clog2(HOLD_MAX)-1:0]                 hold_cnt;
  logic [                 1:0]                 color_sel;
  logic                                        color_sel_inc;

  // see comment in color_hold block for why we pull this out
  logic                                        vga_visible;

  //
  // gen the sync signals
  //
  // Ok, so I already had this written and I'm reusing it. Cheating? Maybe,
  // but I argue it would have been easier to blink leds than to instantiate
  // this module and mux the colors like I'm doing.
  //
  vga_sync #(
      .H_VISIBLE    (H_VISIBLE),
      .H_FRONT_PORCH(H_FRONT_PORCH),
      .H_SYNC_PULSE (H_SYNC_PULSE),
      .H_BACK_PORCH (H_BACK_PORCH),
      .H_WHOLE_LINE (H_WHOLE_LINE),
      .V_VISIBLE    (V_VISIBLE),
      .V_FRONT_PORCH(V_FRONT_PORCH),
      .V_SYNC_PULSE (V_SYNC_PULSE),
      .V_BACK_PORCH (V_BACK_PORCH),
      .V_WHOLE_FRAME(V_WHOLE_FRAME)
  ) vga_sync_i (
      .clk    (clk),
      .reset  (reset),
      .inc    (1'b1),
      .visible(vga_visible),
      .hsync  (vga_hsync),
      .vsync  (vga_vsync),
      .x      (),
      .y      ()
  );

  //
  // color hold
  //
  always_ff @(posedge clk) begin
    if (reset) begin
      hold_cnt      <= 0;
      color_sel_inc <= 1'b0;
    end else begin
      // If we are being super anal, we shouldn't advance the color during the
      // blanking period, as we will otherwise be displaying colors for some
      // rotating unequal amount of time (although, the discrepancy would have
      // been small)
      if (vga_visible && hold_cnt < HOLD_MAX) begin
        hold_cnt      <= hold_cnt + 1;
        color_sel_inc <= 1'b0;
      end else begin
        hold_cnt      <= 0;
        color_sel_inc <= 1'b0;
      end
    end
  end

  //
  // color_sel
  //
  always_ff @(posedge clk) begin
    if (reset) begin
      color_sel <= 0;
    end else begin
      if (color_sel_inc) begin
        if (color_sel < 2) begin
          color_sel <= color_sel + 1;
        end else begin
          color_sel <= 0;
        end
      end
    end
  end

  // Red, Yellow, Green
  assign colors[0] = {COLOR_BITS'(1), COLOR_BITS'(0), COLOR_BITS'(0)};
  assign colors[1] = {COLOR_BITS'(1), COLOR_BITS'(1), COLOR_BITS'(0)};
  assign colors[2] = {COLOR_BITS'(0), COLOR_BITS'(1), COLOR_BITS'(0)};

  // mux the pixel output
  assign {vga_red, vga_grn, vga_blu} = colors[color_sel];

endmodule
`else
module tlight;
endmodule
`endif

`endif
