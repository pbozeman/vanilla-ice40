`ifndef ADC_XY_AXI_V
`define ADC_XY_AXI_V

`include "directives.sv"

`include "cdc_fifo.sv"
`include "delay.sv"

module adc_xy_axi #(
    parameter DATA_BITS = 10
) (
    input logic clk,
    input logic adc_clk,
    input logic reset,

    input logic enable,

    output logic tvalid,
    input  logic tready,

    input logic [DATA_BITS-1:0] adc_x_io,
    input logic [DATA_BITS-1:0] adc_y_io,
    input logic                 adc_red_io,
    input logic                 adc_grn_io,
    input logic                 adc_blu_io,

    output logic [DATA_BITS-1:0] adc_x,
    output logic [DATA_BITS-1:0] adc_y,
    output logic                 adc_red,
    output logic                 adc_grn,
    output logic                 adc_blu
);
  // X/Y + color
  localparam FIFO_WIDTH = DATA_BITS * 2 + 3;
  localparam MAX_ADC = {DATA_BITS{1'b1}};

  logic                  w_data_changed;

  logic                  fifo_w_inc;
  logic [FIFO_WIDTH-1:0] fifo_w_data;
  logic [FIFO_WIDTH-1:0] fifo_w_data_prev;

  logic                  fifo_r_inc;
  logic                  fifo_r_empty;
  logic [FIFO_WIDTH-1:0] fifo_r_data;

  // pipeline scaling in the caller's coordinates
  logic [ DATA_BITS-1:0] adc_x_io_scaled_p1;
  logic [ DATA_BITS-1:0] adc_y_io_scaled_p1;

  // delay the color to match the adc x/y
  //
  // Right now, color is available immediately, so the color needs to be
  // delayed for the full duration of the x/y adc. Adjust this if/when a color
  // adc is added.
  logic                  adc_red_io_d;
  logic                  adc_grn_io_d;
  logic                  adc_blu_io_d;

  // internal versions of the signals because we don't always pass them to the
  // caller, specifically, if the color is black, we don't pass it.
  logic [ DATA_BITS-1:0] adc_x_int;
  logic [ DATA_BITS-1:0] adc_y_int;
  logic                  adc_red_int;
  logic                  adc_grn_int;
  logic                  adc_blu_int;

  logic                  w_pixel_lit;

  // Data sheet for the adc says 7 cycle delay for x/y, plus one cycle to
  // scale io
  delay #(
      .DELAY_CYCLES(7 + 1),
      .WIDTH       (3)
  ) adc_color_delay (
      .clk(adc_clk),
      .in ({adc_red_io, adc_grn_io, adc_blu_io}),
      .out({adc_red_io_d, adc_grn_io_d, adc_blu_io_d})
  );

  // Temporary work around for the fact that our signal is 0 to 1024 while our
  // fb is 640x480. Just get something on the screen as a POC.
  //
  // Also, move this outside this module.
  always_ff @(posedge adc_clk) begin
    adc_x_io_scaled_p1 <= (MAX_ADC - adc_x_io) >> 1;
    adc_y_io_scaled_p1 <= adc_y_io >> 1;
  end

  assign fifo_w_data = {
    adc_x_io_scaled_p1,
    adc_y_io_scaled_p1,
    adc_red_io_d,
    adc_grn_io_d,
    adc_blu_io_d
  };

  assign w_pixel_lit = (adc_red_io_d || adc_grn_io_d || adc_blu_io_d);

  assign {adc_x_int, adc_y_int, adc_red_int, adc_grn_int, adc_blu_int} =
      fifo_r_data;

  cdc_fifo #(
      .DATA_WIDTH(FIFO_WIDTH),
      .ADDR_SIZE (4)
  ) fifo (
      .w_clk        (adc_clk),
      .w_rst_n      (~reset),
      .w_inc        (fifo_w_inc),
      .w_data       (fifo_w_data),
      .w_full       (),
      .w_almost_full(),
      .r_clk        (clk),
      .r_rst_n      (~reset),
      .r_inc        (fifo_r_inc),
      .r_empty      (fifo_r_empty),
      .r_data       (fifo_r_data)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      tvalid <= 0;
    end else begin
      if (tvalid && tready) begin
        tvalid <= 1'b0;
      end else if (!tvalid && !fifo_r_empty) begin
        tvalid  <= 1'b1;
        adc_x   <= adc_x_int;
        adc_y   <= adc_y_int;
        adc_red <= adc_red_int;
        adc_grn <= adc_grn_int;
        adc_blu <= adc_blu_int;
      end
    end
  end

  always_ff @(posedge adc_clk) begin
    fifo_w_data_prev <= fifo_w_data;
  end

  assign w_data_changed = fifo_w_data != fifo_w_data_prev;
  assign fifo_w_inc     = enable && w_pixel_lit && w_data_changed;
  assign fifo_r_inc     = tvalid && tready;

endmodule

`endif
