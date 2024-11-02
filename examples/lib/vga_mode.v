`ifndef VGA_DEF_V
`define VGA_DEV_V

`include "directives.v"

// When compliling with yosys we pass in the vga mode
// from the command line. There isn't a convenient
// way to do this in icecube2 that can easily be changed
// in all the projects, so set a VGA mode here.
`ifndef SYNTH_YOSYS
//`define VGA_MODE_640_480_60 1
`define VGA_MODE_800_600_60 1
`endif

// verilog_format: off
`ifdef VGA_MODE_1024_768_60
  // the pixel clock is too fast for sram, as the sram is currently used
  `include "VGA_MODE_1024_768_60 is broken (consider this an error directive)"

  // icepll -i 100 -o 65
  `define VGA_MODE_PLL_DIVR (4'd4)
  `define VGA_MODE_PLL_DIVF (7'd51)
  `define VGA_MODE_PLL_DIVQ (3'd4)
  `define VGA_MODE_PLL_FILTER_RANGE (3'd2)

  // http://www.tinyvga.com/vga-timing/1024x768@60Hz
  `define VGA_MODE_H_VISIBLE      1024
  `define VGA_MODE_H_FRONT_PORCH  24
  `define VGA_MODE_H_SYNC_PULSE   136
  `define VGA_MODE_H_BACK_PORCH   160
  `define VGA_MODE_H_WHOLE_LINE   1344

  `define VGA_MODE_V_VISIBLE      768
  `define VGA_MODE_V_FRONT_PORCH  3
  `define VGA_MODE_V_SYNC_PULSE   6
  `define VGA_MODE_V_BACK_PORCH   29
  `define VGA_MODE_V_WHOLE_FRAME  806

  `define VGA_MODE_TB_PIXEL_CLK 7.69
`else
`ifdef VGA_MODE_800_600_60
  // icepll -i 100 -o 40
  `define VGA_MODE_PLL_DIVR (4'd4)
  `define VGA_MODE_PLL_DIVF (7'd31)
  `define VGA_MODE_PLL_DIVQ (3'd4)
  `define VGA_MODE_PLL_FILTER_RANGE (3'd2)

  // http://www.tinyvga.com/vga-timing/800x600@60Hz
  `define VGA_MODE_H_VISIBLE      800
  `define VGA_MODE_H_FRONT_PORCH  40
  `define VGA_MODE_H_SYNC_PULSE   128
  `define VGA_MODE_H_BACK_PORCH   88
  `define VGA_MODE_H_WHOLE_LINE   1056

  `define VGA_MODE_V_VISIBLE      600
  `define VGA_MODE_V_FRONT_PORCH  1
  `define VGA_MODE_V_SYNC_PULSE   4
  `define VGA_MODE_V_BACK_PORCH   23
  `define VGA_MODE_V_WHOLE_FRAME  628

  `define VGA_MODE_TB_PIXEL_CLK 12.5
`else
`ifdef VGA_MODE_640_480_60
  // icepll -i 100 -o 25
  `define VGA_MODE_PLL_DIVR (4'd0)
  `define VGA_MODE_PLL_DIVF (7'd7)
  `define VGA_MODE_PLL_DIVQ (3'd5)
  `define VGA_MODE_PLL_FILTER_RANGE (3'd5)

  // http://www.tinyvga.com/vga-timing/640x480@60Hz
  `define VGA_MODE_H_VISIBLE      640
  `define VGA_MODE_H_FRONT_PORCH  16
  `define VGA_MODE_H_SYNC_PULSE   96
  `define VGA_MODE_H_BACK_PORCH   48
  `define VGA_MODE_H_WHOLE_LINE   800

  `define VGA_MODE_V_VISIBLE      480
  `define VGA_MODE_V_FRONT_PORCH  10
  `define VGA_MODE_V_SYNC_PULSE   2
  `define VGA_MODE_V_BACK_PORCH   33
  `define VGA_MODE_V_WHOLE_FRAME  525

  `define VGA_MODE_TB_PIXEL_CLK 20
`else
  // There's no `error, so this will have to do
  `include "bad or missing VGA_MODE_ define (consider this an error directive)"
`endif
`endif
`endif
// verilog_format: on

`endif
